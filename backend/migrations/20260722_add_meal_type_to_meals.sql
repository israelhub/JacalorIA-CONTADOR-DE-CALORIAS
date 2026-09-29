ALTER TABLE meals
  ADD COLUMN IF NOT EXISTS meal_type VARCHAR(32) NOT NULL DEFAULT 'free';

UPDATE meals
SET meal_type = 'breakfast'
WHERE meal_type = 'free'
  AND (
    lower(title) LIKE '%café%'
    OR lower(title) LIKE '%cafe%'
  );

UPDATE meals
SET meal_type = 'lunch'
WHERE meal_type = 'free'
  AND lower(title) LIKE '%almo%';

UPDATE meals
SET meal_type = 'dinner'
WHERE meal_type = 'free'
  AND (
    lower(title) LIKE '%jantar%'
    OR lower(title) LIKE '%janta%'
  );
