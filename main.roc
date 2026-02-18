app [main!] {
    pf: platform "https://github.com/roc-lang/basic-cli/releases/download/0.20.0/X73hGh05nNTkDHU06FHC0YfFaQB1pimX7gncRcao5mU.tar.br",
}

import pf.Stdout
import J2000

degToRad = |deg|
    deg * (Num.pi / 180.0)
radToDeg = |rad|
    rad * (180.0 / Num.pi)

calcMeanObliquityOfEcliptic = |t|
    # sekundy = 21.448 - t * (46.8150 + t * (0.00059 - t * (0.001813)))
    seconds = 21.448 - t * (46.8150 + t * (0.00059 - t * (0.001813)))
    # e0 = 23.0 + (26.0 + (seconds / 60.0)) / 60.0
    23.0 + (26.0 + (seconds / 60.0)) / 60.0

calcObliquityCorrection = |t|
    e0 = calcMeanObliquityOfEcliptic t
    omega = 125.04 - 1934.136 * t
    # e = e0 + 0.00256 * cos(degToRad(omega))
    e0 + 0.00256 * Num.cos (degToRad omega)

normalizeDegrees = |angle|
    if
        angle < 0
    then
        normalizeDegrees (angle + 360.0)
    else if
        angle >= 360.0
    then
        normalizeDegrees (angle - 360.0)
    else
        angle
# 1. Kąt już znajduje się w zakresie [0, 360)
expect normalizeDegrees 120.5 == 120.5
# 2. Kąt przekracza 360 stopni (powinien zostać zredukowany)
# 730 - (2 * 360) = 10
expect normalizeDegrees 730.0 == 730.0 - 2 * 360.0
# 3. Kąt jest ujemny (powinien zostać przesunięty do dodatniego zakresu)
expect normalizeDegrees -45.0 == -45.0 + 360.0
# 4. Kąt jest dokładnie wielokrotnością 360 (powinien zwrócić 0)
expect normalizeDegrees 360.0 == 0.0

calcGeomMeanLongSun = |t|
    #    # Bazowe obliczenie
    l0Raw = 280.46646 + t * (36000.76983 + 0.0003032 * t)
    #    # Normalizacja do zakresu [0, 360)
    normalizeDegrees l0Raw

calcEccentricityEarthOrbit = |t|
    0.016708634 - t * (0.000042037 + 0.0000001267 * t)

calcGeomMeanAnomalySun = |t|
    mRaw = 357.52911 + t * (35999.05029 - 0.0001537 * t)
    normalizeDegrees mRaw

calcEquationOfTime = |t|
    epsilon = calcObliquityCorrection t
    l0 = calcGeomMeanLongSun t
    e = calcEccentricityEarthOrbit t
    m = calcGeomMeanAnomalySun t

    y = Num.tan (degToRad (epsilon / 2.0))
    ySq = y * y

    sin2l0 = Num.sin (2.0 * degToRad l0)
    sinm = Num.sin (degToRad m)
    cos2l0 = Num.cos (2.0 * degToRad l0)
    sin4l0 = Num.sin (4.0 * degToRad l0)
    sin2m = Num.sin (2.0 * degToRad m)

    # Równanie czasu w radianach
    etimeRad = ySq * sin2l0 - 2.0 * e * sinm + 4.0 * e * ySq * sinm * cos2l0 - 0.5 * ySq * ySq * sin4l0 - 1.25 * e * e * sin2m

    # Konwersja na minuty czasu (1 stopień = 4 minuty)
    radToDeg etimeRad * 4.0

calcSunTrueLong = |t|
    l0 = calcGeomMeanLongSun t
    c = calcSunEqOfCenter t
    l0 + c

calcSunEqOfCenter = |t|
    m = calcGeomMeanAnomalySun t
    mRad = degToRad m

    # Współczynniki dla szeregu Fouriera
    c1 = Num.sin mRad * (1.914602 - t * (0.004817 + 0.000014 * t))
    c2 = Num.sin (2.0 * mRad) * (0.019993 - 0.000101 * t)
    c3 = Num.sin (3.0 * mRad) * 0.000289

    c1 + c2 + c3

calcSunApparentLong = |t|
    l0 = calcSunTrueLong t
    omega = 125.04 - 1934.136 * t
    l0 - 0.00569 - 0.00478 * Num.sin (degToRad omega)

calcSunDeclination = |t|
    e = calcObliquityCorrection t
    lambda = calcSunApparentLong t

    sinTheta = Num.sin (degToRad e) * Num.sin (degToRad lambda)
    radToDeg (Num.asin sinTheta)

calcSolarAzimuth = |lat, solarDec, hourAngle, zenith|
    latRad = degToRad lat
    zenRad = degToRad zenith
    decRad = degToRad solarDec

    # JS: var azDenom = ( Math.cos(degToRad(latitude)) * Math.sin(degToRad(zenith)) );
    azDenom = Num.cos latRad * Num.sin zenRad

    if Num.abs azDenom > 0.001 then
        # JS: azRad = (( Math.sin(degToRad(latitude)) * Math.cos(degToRad(zenith)) ) - Math.sin(degToRad(solarDec))) / azDenom;
        azRadRaw = ((Num.sin latRad * Num.cos zenRad) - Num.sin decRad) / azDenom

        # JS: if (Math.abs(azRad) > 1.0) { ... }
        azRad =
            if azRadRaw > 1.0 then
                1.0
            else if azRadRaw < -1.0 then
                -1.0
            else
                azRadRaw

        # JS: var azimuth = 180.0 - radToDeg(Math.acos(azRad));
        azimuthRaw = 180.0 - radToDeg (Num.acos azRad)

        # JS: if (hourAngle > 0.0) { azimuth = -azimuth; }
        azimuthCorrected = if hourAngle > 0.0 then -azimuthRaw else azimuthRaw

        # JS: if (azimuth < 0.0) { azimuth += 360.0; }
        if azimuthCorrected < 0.0 then azimuthCorrected + 360.0 else azimuthCorrected
    else if lat > 0.0 then
        180.0
    else
        0.0

calcZenith = |latitude, solarDec, hourAngle|
    latRad = degToRad latitude
    decRad = degToRad solarDec
    haRad = degToRad hourAngle

    # Obliczenie cosinusa kąta zenitalnego (csz)
    cszRaw =
        (Num.sin latRad * Num.sin decRad)
        +
        (Num.cos latRad * Num.cos decRad * Num.cos haRad)

    # JS: if (csz > 1.0) { csz = 1.0; } else if (csz < -1.0) { csz = -1.0; }
    csz =
        if cszRaw > 1.0 then
            1.0
        else if cszRaw < -1.0 then
            -1.0
        else
            cszRaw

    # JS: var zenith = radToDeg(Math.acos(csz));
    radToDeg (Num.acos csz)

calcSun = |year, month, day, hour, min, sec, zone, lat, lon|
    # 1. Czas UTC i T
    timeNow = Num.to_frac hour + (Num.to_frac min / 60.0) + (Num.to_frac sec / 3600.0) + zone
    t = J2000.calcT year month day timeNow

    # 2. Dane bazowe
    eqTime = calcEquationOfTime t
    solarDec = calcSunDeclination t

    # 3. Kąt godzinny (Hour Angle)
    solarTimeFix = eqTime - 4.0 * lon + 60.0 * zone
    trueSolarTime = (Num.to_frac hour * 60.0) + Num.to_frac min + (Num.to_frac sec / 60.0) + solarTimeFix

    haRaw = (trueSolarTime / 4.0) - 180.0
    hourAngle = if haRaw < -180.0 then haRaw + 360.0 else haRaw

    # 4. Pozycja (Azymut i Zenit)
    # Tu wywołaj funkcje z poprzednich kroków używając hourAngle i solarDec
    zenith = calcZenith lat solarDec hourAngle
    {
        trueSolarTime,
        equationOfTime: eqTime,
        declination: solarDec,
        azimuth: calcSolarAzimuth lat solarDec hourAngle zenith,
        # implementacja wg logiki wyżej
    }

main! = |_args|
    # latitude = 50.031196
    # longitude = 18.7018069
    latitude = 50.0
    longitude = 18.0
    sun = calcSun 2026 2 15 12 0 0 1 latitude longitude
    declination = sun.declination |> Num.to_str
    equationOfTime = sun.equationOfTime |> Num.to_str
    trueSolarTime = sun.trueSolarTime |> Num.to_str
    azimuth = sun.azimuth |> Num.to_str
    Stdout.line!("sun declination ${equationOfTime}")?
    Stdout.line!("declination ${declination}")?
    Stdout.line!("trueSolarTime ${trueSolarTime}")?
    Stdout.line!("azimuth ${azimuth}")
