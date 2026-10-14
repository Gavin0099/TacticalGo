process.env.INTERFACE_PREVIEW_URL ||= 'http://127.0.0.1:8771/tools/game-interface-20/';
process.env.INTERFACE_EVIDENCE_DIR = 'artifacts/game-interface-20';
require('./review-game-interface.cjs');
