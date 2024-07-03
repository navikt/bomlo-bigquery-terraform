SELECT vedtaksperiodeId::text,
       skjaeringstidspunkt,
       tidsstempel,
       ventetsiden,
       ventertil,
       venterforalltid,
       venterpavedtaksperiodeid::text,
       venterpahva,
       venterpahvorfor,
       venterpaskjaeringstidspunkt,
       hendelseid::text
FROM vedtaksperiode_venter
WHERE tidsstempel < now() - INTERVAL '5 MINUTES'
