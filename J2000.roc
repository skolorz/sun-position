module [
    calcT,
    calcJD,
]

## Oblicza Dzień Juliański (Julian Day)
calcJD = |year, month, day, hour|
    { y, m } = if month <= 2 then
        { y: year - 1, m: month + 12 }
    else
        { y: year, m: month }

    a = Num.floor(y / 100.0)
    b = Num.to_frac(2 - a + Num.div_trunc a 4)

    jd =
        (365.25 * (y + 4716.0))
        + (30.6001 * (m + 1.0))
        + day
        + b
        - 1524.5

    jd + (hour / 24.0)

## Oblicza stulecia juliańskie od epoki J2000.0
calcT = |year, month, day, hour|
    jd = calcJD year month day hour
    (jd - 2451545.0) / 36525.0

expect calcT 2026 2 15 0 == 0.26124001825233434
