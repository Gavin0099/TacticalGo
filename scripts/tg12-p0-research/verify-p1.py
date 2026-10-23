"""Check persisted P1 receipts with the existing Core record reader (Python stdlib).

This proves replay consistency, not independent rule correctness or best play.
Each candidate and response retains the complete original opening prefix.
"""
import argparse
from collections import Counter
import copy
import json
from pathlib import Path
import subprocess
import tempfile


def load(path):
    return json.loads(path.read_text())


def verify(report, cohort, runner, negative_control=False):
    assert report['study'] == 'TG12_P1_SAME_STATE_COUNTERFACTUAL_V2'
    replays = 0
    risk_counts = Counter()
    positions = []
    with tempfile.TemporaryDirectory(prefix='tg12-p1-replay-') as folder:
        path = Path(folder) / 'candidate.json'

        def replay(record, actions, expected, should_pass=True):
            nonlocal replays
            candidate = dict(record, actions=actions, expected=expected)
            path.write_text(json.dumps(candidate))
            result = subprocess.run([str(runner), 'verify-record', str(path)],
                                    capture_output=True, text=True)
            if should_pass:
                assert result.returncode == 0, result.stderr
                replays += 1
            else:
                assert result.returncode == 1, 'Corrupt reply receipt was accepted'

        for position in report['positions']:
            directory = cohort / position['game']
            trace, record = load(directory / 'trace.json'), load(directory / 'record.json')
            turn = position['turn']
            row = trace['turns'][turn]
            before = next(f['before'] for f in trace['frames'] if f['turn'] == turn)
            assert (row['heroClass'], row['ply']) == (position['hero'], position['ply'])
            assert position['before'] == before
            assert position['originalBotActions'] == row['actions']
            reason = position['sourceSelectionReason']

            def qualifies(other):
                if other['heroClass'] != position['hero']:
                    return False
                if reason == 'first-advanced-legal-ordinary-two-soldiers':
                    return other['pattern'] == 'soldier+soldier' and other['availability']['advancedLegal']
                assert reason == 'first-observed-skill-soldier'
                return other['pattern'] in ('skill+soldier', 'soldier+skill')

            # Earliest within this selected source game, not a cohort-global claim.
            assert next(r['index'] for r in trace['turns'] if qualifies(r)) == turn
            prefix = [f['action'] for f in trace['frames'] if f['turn'] < turn]
            alternatives = position['alternatives']
            assert dict(Counter(a['group'] for a in alternatives)) == position['sampledCounts']
            observed = [a for a in alternatives if a['origin'] == 'P0_observed_Bot_plan']
            assert len(observed) == 1 and observed[0]['actions'] == row['actions']
            group_rows = []
            for number, alternative in enumerate(alternatives):
                assert len(alternative['actions']) == 2
                actions = prefix + alternative['actions']
                replay(record, actions, alternative['after'])
                actor = position['actor']
                assert alternative['manaSpent'] == before['mana'][actor] - alternative['after']['mana'][actor]
                reply = alternative['reply']
                if reply['applicable']:
                    replay(record, actions + reply['recordActions'], reply['after'])
                    assert reply['ourManaAfterStandardReply'] == reply['after']['mana'][actor]
                    assert reply['ourCommanderAliveAfterStandardReply'] == (('X' if actor == 0 else 'O') in reply['after']['board'])
                probe = alternative['immediateLossProbe']
                if probe['verdict'] == 'opponent_can_win':
                    replay(record, actions + probe['recordActions'], probe['after'])
                    assert probe['after']['status'] == 'Won' and probe['after']['winner'] == 1 - actor
                elif probe['verdict'] == 'not_found_within_bounded_reply_sample':
                    assert probe['provesSafe'] is False
                known_loss = reply.get('ourCommanderAliveAfterStandardReply') is False
                risk_counts['standardReplyLoss'] += known_loss
                risk_counts['boundedWinningWitness'] += probe['verdict'] == 'opponent_can_win'
                risk_counts['standardLossMissedByBoundedSample'] += known_loss and probe['verdict'] != 'opponent_can_win'
                group_rows.append({
                    'candidate': number, 'group': alternative['group'],
                    'observed': alternative['origin'] == 'P0_observed_Bot_plan',
                    'advanced': alternative['advancedSkillUsed'], 'manaSpent': alternative['manaSpent'],
                    'immediateCaptures': alternative['enemySoldiersCaptured'],
                    'netSoldierCapturesAfterStandardReply': alternative['enemySoldiersCaptured'] - reply.get('standardBotCapturedOurSoldiers', 0),
                    'ourCommanderAliveAfterStandardReply': reply.get('ourCommanderAliveAfterStandardReply'),
                    'ourLibertiesAfterStandardReply': reply.get('ourCommanderLibertiesAfterStandardReply'),
                    'enemyLibertiesAfterStandardReply': reply.get('enemyCommanderLibertiesAfterStandardReply'),
                    'boundedReplyProbe': probe['verdict'],
                    'standardReplyBudgetExhausted': reply.get('opponentSearchBudgetExhausted')})
            positions.append({'game': position['game'], 'turn': turn, 'ply': position['ply'],
                              'hero': position['hero'], 'reason': reason, 'candidates': group_rows})
        if negative_control:
            first = report['positions'][0]
            directory = cohort / first['game']
            record, trace = load(directory / 'record.json'), load(directory / 'trace.json')
            prefix = [f['action'] for f in trace['frames'] if f['turn'] < first['turn']]
            plan = first['alternatives'][0]
            corrupt = copy.deepcopy(plan['reply']['after'])
            corrupt['ap'] += 1
            replay(record, prefix + plan['actions'] + plan['reply']['recordActions'], corrupt, should_pass=False)
    return {'positions': len(positions), 'plans': sum(len(p['candidates']) for p in positions),
            'coreRecordReplays': replays, 'negativeReplyAPControlRejected': negative_control,
            'riskCounts': dict(risk_counts), 'comparisons': positions,
            'claimBoundary': 'Selected own plans and one Standard reply only; negative bounded risk probes remain unknown; no best reply, dominance, balance or human-fun proof.'}


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('report', type=Path)
    parser.add_argument('cohort', type=Path)
    parser.add_argument('runner', type=Path)
    parser.add_argument('--negative-control', action='store_true')
    parser.add_argument('--output', type=Path)
    args = parser.parse_args()
    summary = verify(load(args.report), args.cohort, args.runner.resolve(), args.negative_control)
    if args.output:
        args.output.write_text(json.dumps(summary, indent=2) + '\n')
    print(json.dumps({k: v for k, v in summary.items() if k != 'comparisons'}))
