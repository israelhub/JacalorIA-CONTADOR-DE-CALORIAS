import {
  extractJsonText,
  normalizeImportedRoutines,
  parseReps,
  toDateOnly,
} from './workout-import.util';

const assert = (condition: unknown, message: string) => {
  if (!condition) {
    throw new Error(message);
  }
};

const routines = normalizeImportedRoutines(
  {
    treinos: [
      {
        nome: '  Treino A  ',
        exercicios: [
          {
            nome: 'Supino reto',
            series: 4,
            repeticoes: '8-12',
            cargas: [
              { peso: '40', data: '20/09/2026' },
              { weight: 42.5, date: '2026-09-22' },
              { peso: 41, data: '20/09/2026' },
            ],
          },
          {
            nome: '',
            series: 3,
          },
        ],
      },
    ],
  },
  2026,
);

assert(routines.length === 1, 'deveria manter um treino');
assert(routines[0].name === 'Treino A', 'nome do treino normalizado');
assert(routines[0].exercises.length === 1, 'ignora exercicio sem nome');
assert(routines[0].exercises[0].sets === 4, 'series');
assert(routines[0].exercises[0].reps === 10, 'media de 8-12');
assert(routines[0].exercises[0].loads.length === 2, 'carga do mesmo dia sobrescreve');
assert(routines[0].exercises[0].loads[0].recordedAt === '2026-09-20', 'data BR');
assert(routines[0].exercises[0].loads[0].weight === 41, 'ultima carga do dia vence');
assert(parseReps('10') === 10, 'reps simples');
assert(toDateOnly('12/09', 2026) === '2026-09-12', 'completa ano atual');
assert(extractJsonText('```json\n{"ok":true}\n```') === '{"ok":true}', 'remove fence');

console.log('workout-import.util.test ok');
