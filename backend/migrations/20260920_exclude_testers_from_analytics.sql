-- Testers fora da amostra da pesquisa / dashboard (mesmo filtro is_dev).
-- John H. Saraiva: cadastrou e não completou onboarding.
-- Roberta Sarah (rlimadosreis@gmail.com): uso residual (2 dias, 1 refeição).
UPDATE users
SET is_dev = TRUE
WHERE lower(email) IN (
  'johnnn.h@gmail.com',
  'rlimadosreis@gmail.com'
);
