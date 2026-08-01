import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import {
  buildMatchableFood,
  findBestFoodMatch,
  hasWordBoundaryMatch,
} from './food-match.util';

const MATCH_THRESHOLD = 0.58;

const CATALOG = [
  buildMatchableFood({
    description: 'Mamão verde, doce em calda, drenado',
    category: 'Frutas e derivados',
  }),
  buildMatchableFood({
    description: 'Mamão, doce em calda, drenado',
    category: 'Frutas e derivados',
  }),
  buildMatchableFood({
    description: 'Mamão, Formosa, cru',
    category: 'Frutas e derivados',
  }),
  buildMatchableFood({
    description: 'Mamão, Papaia, cru',
    category: 'Frutas e derivados',
  }),
  buildMatchableFood({
    description: 'Água',
    category: 'Bebidas (alcoólicas e não alcoólicas)',
  }),
  buildMatchableFood({
    description: 'Água, mineral',
    category: 'Bebidas (alcoólicas e não alcoólicas)',
  }),
  buildMatchableFood({
    description: 'Cana, aguardente 1',
    category: 'Bebidas (alcoólicas e não alcoólicas)',
  }),
  buildMatchableFood({
    description: 'Coco, água de',
    category: 'Frutas e derivados',
  }),
  buildMatchableFood({
    description: 'Corvina de água doce, crua',
    category: 'Pescados e frutos do mar',
  }),
  buildMatchableFood({
    description: 'Refrigerante, tipo água tônica',
    category: 'Bebidas (alcoólicas e não alcoólicas)',
  }),
  buildMatchableFood({
    description: 'Frango, peito, sem pele, cru',
    category: 'Carnes e derivados',
  }),
  buildMatchableFood({
    description: 'Frango, peito, sem pele, grelhado',
    category: 'Carnes e derivados',
  }),
  buildMatchableFood({
    description: 'Frango, peito, sem pele, cozido',
    category: 'Carnes e derivados',
  }),
  buildMatchableFood({
    description: 'Frango, peito, com pele, assado',
    category: 'Carnes e derivados',
  }),
  buildMatchableFood({
    description: 'Frango, coração, grelhado',
    category: 'Carnes e derivados',
  }),
  buildMatchableFood({
    description: 'Frango, filé, à milanesa',
    category: 'Carnes e derivados',
  }),
  buildMatchableFood({
    description: 'Coxinha de frango, frita',
    category: 'Carnes e derivados',
  }),
  buildMatchableFood({
    description: 'Ovo, de galinha, inteiro, frito',
    category: 'Ovos e derivados',
  }),
  buildMatchableFood({
    description: 'Ovo, de galinha, inteiro, cozido',
    category: 'Ovos e derivados',
  }),
  buildMatchableFood({
    description: 'Ovo, de galinha, gema, cozida/10minutos',
    category: 'Ovos e derivados',
  }),
  buildMatchableFood({
    description: 'Feijão, carioca, cru',
    category: 'Leguminosas e derivados',
  }),
  buildMatchableFood({
    description: 'Feijão, carioca, cozido',
    category: 'Leguminosas e derivados',
  }),
  buildMatchableFood({
    description: 'Feijão, preto, cru',
    category: 'Leguminosas e derivados',
  }),
  buildMatchableFood({
    description: 'Feijão, preto, cozido',
    category: 'Leguminosas e derivados',
  }),
  buildMatchableFood({
    description: 'Feijão, jalo, cru',
    category: 'Leguminosas e derivados',
  }),
];

function match(query: string) {
  return findBestFoodMatch(query, CATALOG, MATCH_THRESHOLD);
}

describe('food-match.util', () => {
  it('não casa agua dentro de aguardente via substring', () => {
    assert.equal(
      hasWordBoundaryMatch('cana aguardente 1', 'agua'),
      false,
    );
    assert.equal(hasWordBoundaryMatch('coco agua de', 'agua'), true);
  });

  it('mamão prefere Formosa/Papaia cru, não doce em calda', () => {
    const result = match('mamão');
    assert.ok(result);
    assert.match(result.food.description, /Formosa|Papaia/i);
    assert.doesNotMatch(result.food.description, /doce|calda/i);

    const kcalPer100 = result.food.description.includes('Formosa') ? 45.34 : 40.16;
    const kcal163 = Math.round((kcalPer100 * 163) / 100);
    assert.ok(kcal163 >= 65 && kcal163 <= 74, `esperado ~70 kcal, veio ${kcal163}`);
  });

  it('mamão doce em calda casa com doce em calda', () => {
    const result = match('mamão doce em calda');
    assert.ok(result);
    assert.match(result.food.description, /doce em calda/i);
  });

  it('frango sem preparo prioriza peito grelhado (não cru, milanesa, coração)', () => {
    const result = match('frango');
    assert.ok(result);
    assert.equal(
      result.food.description,
      'Frango, peito, sem pele, grelhado',
    );
  });

  it('frango grelhado sem corte também prioriza peito', () => {
    const result = match('frango grelhado');
    assert.ok(result);
    assert.match(result.food.description, /peito/i);
    assert.match(result.food.description, /grelhado/i);
  });

  it('frango à milanesa casa com milanesa', () => {
    for (const query of ['frango à milanesa', 'frango a milanesa']) {
      const result = match(query);
      assert.ok(result, query);
      assert.match(result.food.description, /milanesa/i);
    }
  });

  it('frango peito grelhado casa com peito grelhado', () => {
    const result = match('frango peito grelhado');
    assert.ok(result);
    assert.equal(
      result.food.description,
      'Frango, peito, sem pele, grelhado',
    );
  });

  it('água casa com Água (não aguardente)', () => {
    const result = match('água');
    assert.ok(result);
    assert.equal(result.food.description, 'Água');
  });

  it('água mineral casa com Água, mineral', () => {
    const result = match('água mineral');
    assert.ok(result);
    assert.equal(result.food.description, 'Água, mineral');
  });

  it('agua não elege Cana, aguardente', () => {
    const result = match('agua');
    assert.ok(result);
    assert.notEqual(result.food.description, 'Cana, aguardente 1');
    assert.match(result.food.description, /^Água/i);
  });

  it('ovo frito casa com ovo de galinha inteiro frito', () => {
    const result = match('ovo frito');
    assert.ok(result);
    assert.equal(result.food.description, 'Ovo, de galinha, inteiro, frito');
  });

  it('feijão sozinho prefere carioca/preto cozido (não cru)', () => {
    const result = match('feijão');
    assert.ok(result);
    assert.match(result.food.description, /cozido/i);
    assert.doesNotMatch(result.food.description, /\bcru\b/i);
    assert.match(result.food.description, /carioca|preto/i);
  });

  it('feijão preto cru respeita cru quando informado', () => {
    const result = match('feijão preto cru');
    assert.ok(result);
    assert.equal(result.food.description, 'Feijão, preto, cru');
  });
});
