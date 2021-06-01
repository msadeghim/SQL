WITH recursive Subsets AS (
    SELECT  SUBSTRING('ABCDE', Number, 1) AS Token,
            '.'||Number ||'.'  AS Permutation,
            CAST(1 AS INT) AS Iteration
    FROM generate_series(1, 5) d(Number)
    UNION ALL
    SELECT  Token||SUBSTRING('ABCDE', Number, 1) AS Token,
            Permutation||Number ||'.' AS Permutation,
            s.Iteration + 1 AS Iteration
    FROM Subsets s
    JOIN generate_series(1,5) n(Number)
    ON s.Permutation NOT LIKE '%.'|| Number ||'.%'
    AND s.Iteration < 5
)
SELECT *
FROM Subsets
-- WHERE Iteration = 5
ORDER BY Permutation
