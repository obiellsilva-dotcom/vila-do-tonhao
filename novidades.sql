-- ETAPA 36: móvel novo "Luz de teto" (R$ 250). Pode rodar de novo sem perder nada.
create or replace function public.preco_movel(p_tipo text) returns integer
language sql immutable as $$
  select case p_tipo
    when 'parede' then 200 when 'porta' then 600
    when 'caixote' then 80 when 'cadeira' then 150 when 'planta' then 250 when 'colchao' then 300
    when 'tapete' then 400 when 'abajur' then 350 when 'criado' then 450 when 'mesinha' then 500
    when 'mesa' then 900 when 'pia' then 1100 when 'estante' then 1200 when 'fogao' then 1300
    when 'poltrona' then 1400 when 'armario' then 1600 when 'geladeira' then 1800 when 'sofa' then 2200
    when 'tv' then 2500 when 'cama' then 3000 when 'somcx' then 3000 when 'led' then 2000
    when 'aquario' then 6000 when 'homet' then 9000 when 'jukebox' then 12000 else null end
$$;
create or replace function public.preco_movel(p_tipo text) returns integer
language sql immutable as $$
  select case p_tipo
    when 'parede' then 200 when 'porta' then 600
    when 'caixote' then 80 when 'cadeira' then 150 when 'planta' then 250 when 'colchao' then 300
    when 'tapete' then 400 when 'abajur' then 350 when 'criado' then 450 when 'mesinha' then 500
    when 'mesa' then 900 when 'pia' then 1100 when 'estante' then 1200 when 'fogao' then 1300
    when 'poltrona' then 1400 when 'armario' then 1600 when 'geladeira' then 1800 when 'sofa' then 2200
    when 'tv' then 2500 when 'cama' then 3000 when 'somcx' then 3000 when 'led' then 2000
    when 'aquario' then 6000 when 'homet' then 9000 when 'jukebox' then 12000
    when 'vaso' then 700 when 'piabanho' then 900 when 'chuveiro' then 1500 when 'banheira' then 3200 when 'toalheiro' then 400 when 'armpar' then 1100 when 'micro' then 1300 when 'cafeteira' then 800 when 'balcao' then 2600 when 'churras' then 3500 when 'rede' then 900 when 'cadpraia' then 450 when 'piscina' then 1800 when 'gamer' then 4500 when 'cadgamer' then 2200 when 'sofacurvo' then 4800 when 'sofamod' then 5600 when 'painel' then 2400 when 'mesaredonda' then 1300 when 'leitura' then 2000 when 'camaking' then 6500 when 'beliche' then 2400 when 'penteadeira' then 2100 when 'comoda' then 1500 when 'quadro' then 600 when 'quadro2' then 900 when 'espelho' then 1100 when 'taprd' then 700 when 'cortina' then 800 when 'lumichao' then 900 when 'relogio' then 500 when 'plantag' then 700 when 'trofeu' then 1500 when 'lustre' then 18000 when 'piano' then 28000 when 'estatua' then 15000 when 'sofacouro' then 12000 when 'adega' then 9500 when 'vitrola' then 7500 when 'trono' then 20000 when 'hidro' then 24000 when 'massag' then 16000 when 'arcade' then 14000 when 'aqparede' then 22000 when 'lareira' then 8000 when 'globo' then 6000 when 'neon' then 5000 when 'neon2' then 3500 when 'fonte' then 9000 when 'lava' then 2500 when 'luzteto' then 250 else null end
$$;
