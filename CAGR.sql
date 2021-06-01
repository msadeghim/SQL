select  d::date as day,
        round(1.01077551337937624564^n*2000) as goal
from generate_series('2021-03-21', '2022-03-20', interval '1day' ) with ordinality d(d,n)
