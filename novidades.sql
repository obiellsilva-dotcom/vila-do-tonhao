-- Novidades (tudo que ainda não foi rodado). Rode inteiro no Supabase. Pode rodar de novo sem problema.

-- Novidades: provador não dá mais roupa paga de graça. Rode no Supabase.

-- ===================== ETAPA 21: provador não dá mais roupa paga de graça =====================
-- lê os números do visual (TH antigo = 1 dígito por campo; TJ = 2 dígitos por campo)
create or replace function public._vis_nums(v text) returns integer[]
language sql immutable as $$
  select case
    when v ~ '^TH[0-9]+$' then (select array_agg(substr(v, i, 1)::int order by i) from generate_series(3, length(v)) i)
    when v ~ '^TJ[0-9]+$' then (select array_agg(substr(v, i, 2)::int order by i) from generate_series(3, length(v) - 1, 2) i)
  end
$$;

-- confere se a pessoa pode vestir esse visual: peça grátis, peça que já está usando ou peça comprada na loja
create or replace function public._confere_roupas(p_id uuid, v text) returns void
language plpgsql security definer set search_path = public as $$
declare novo integer[] := _vis_nums(v); velho integer[]; ant text; s text; s0 text;
        k integer; i integer; pc text; campos integer[] := array[8, 5, 9, 6, 7, 15]; nomes text[] := array['roupa','calca','calcado','chapeu','extra','estampa'];
begin
  select visual into ant from moradores where id = p_id;
  velho := _vis_nums(coalesce(ant, ''));
  s := case when coalesce(novo[10], 0) = 1 then 'f' else 'm' end;
  s0 := case when coalesce(velho[10], 0) = 1 then 'f' else 'm' end;
  for k in 1..6 loop
    i := coalesce(novo[campos[k]], 0);
    if i >= 50 then continue; end if;  -- peça VIP: conferida à parte
    pc := case when nomes[k] = 'estampa' then 'estampa' else nomes[k] || '_' || s end;
    if preco_roupa(pc, i) = 0 then continue; end if;
    if velho is not null and coalesce(velho[campos[k]], 0) = i and (nomes[k] = 'estampa' or s = s0) then continue; end if;
    if exists (select 1 from guarda_roupa where morador = p_id and guarda_roupa.peca = pc and guarda_roupa.item = i) then continue; end if;
    raise exception '👕 Essa peça é vendida na Loja de Roupas. Compre lá primeiro.';
  end loop;
end $$;
revoke execute on function public._confere_roupas(uuid, text) from public, anon, authenticated;

-- quem já joga fica com as peças que está usando agora (vão para o guarda-roupa)
insert into public.guarda_roupa(morador, peca, item)
select m.id, case when c.n = 'estampa' then 'estampa' else c.n || '_' || case when coalesce(x.a[10], 0) = 1 then 'f' else 'm' end end, x.a[c.p]
from public.moradores m
cross join lateral (select public._vis_nums(m.visual) a) x
cross join (values ('roupa', 8), ('calca', 5), ('calcado', 9), ('chapeu', 6), ('extra', 7), ('estampa', 15)) c(n, p)
where x.a is not null and x.a[c.p] is not null and x.a[c.p] < 50
  and public.preco_roupa(case when c.n = 'estampa' then 'estampa' else c.n || '_' || case when coalesce(x.a[10], 0) = 1 then 'f' else 'm' end end, x.a[c.p]) > 0
on conflict do nothing;

create or replace function public.criar_morador(p_nome text, p_visual text) returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores; n text := btrim(regexp_replace(coalesce(p_nome,''), '\s+', ' ', 'g'));
        v text := upper(coalesce(p_visual,'')); vip boolean;
begin
  if auth.uid() is null then raise exception 'Entre no jogo primeiro.'; end if;
  if coalesce((auth.jwt()->>'is_anonymous')::boolean, false) then raise exception 'Crie sua conta para jogar.'; end if;
  if char_length(n) < 1 or char_length(n) > 22 then raise exception 'O nome precisa ter de 1 a 22 letras.'; end if;
  if v !~ '^(TH[0-9]{7,30}|TJ[0-9]{20,60})$' or (v ~ '^TJ' and length(v) % 2 = 1) then raise exception 'Visual inválido.'; end if;
  if v ~ '^TJ' and exists (select 1 from generate_series(3, length(v) - 1, 2) i where substr(v, i, 2)::int >= 50) then
    select coalesce(vip_ate > now(), false) into vip from moradores where id = auth.uid();
    if not coalesce(vip, false) then raise exception '👑 Essa peça é exclusiva para VIP.'; end if;
  end if;
  perform _confere_roupas(auth.uid(), v);
  n := public.limpar_texto(n);
  if n is distinct from (select nome from moradores where id = auth.uid())
     and exists (select 1 from moradores where id <> auth.uid() and lower(translate(nome,'áàâãäéèêëíìîïóòôõöúùûüçÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇ','aaaaaeeeeiiiiooooouuuucAAAAAEEEEIIIIOOOOOUUUUC')) = lower(translate(n,'áàâãäéèêëíìîïóòôõöúùûüçÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇ','aaaaaeeeeiiiiooooouuuucAAAAAEEEEIIIIOOOOOUUUUC'))) then
    raise exception 'Já existe um morador com esse nome. Escolha outro.';
  end if;
  insert into moradores(id, nome, visual) values (auth.uid(), n, v)
  on conflict (id) do update set nome = excluded.nome, visual = excluded.visual, visto_em = now(),
    fome_em = case when now() - moradores.visto_em > interval '2 minutes' then now() else moradores.fome_em end
    where not moradores.banido
  returning * into m;
  if m.id is null then raise exception 'Você foi banido da cidade.'; end if;
  return _estado(m.id);
end $$;
grant execute on function public.criar_morador(text, text) to authenticated;

-- ===================== ETAPA 22: Esportivo passa a se chamar Rover =====================
update public.loja set nome = 'Rover' where id = 'esportivo' and tipo = 'carro';
update public.produtos set nome = 'Lambordini' where id = 'carro_neon';
update public.loja set nome = 'Jipe Renegado' where id = 'jipe' and tipo = 'carro';

-- ===================== ETAPA 23: Ferrarini na loja do Pix (a Lambordini fica só com o VIP) =====================
insert into public.produtos(id, tipo, item, dias, nome, preco) values ('carro_gto', 'carro', 'gto', 0, 'Ferrarini', 19.90)
on conflict (id) do update set nome = excluded.nome, preco = excluded.preco, item = excluded.item;

-- ===================== ETAPA 24: XP por tarefa 2x maior (t.xp/5) =====================
create or replace function public.tarefa_feita() returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores; t public.trabalhos; extra integer; pago integer; ganho integer; novo_xp integer;
        novo_nivel integer; premio integer := 0; peixes_ganhos integer := 0; morreu boolean; cansado boolean := false;
begin
  m := _eu();
  if m.trabalho is null then raise exception 'Você não está trabalhando.'; end if;
  if m.tarefa_em is not null and now() - m.tarefa_em < interval '2.5 seconds' then
    raise exception 'Calma! Uma tarefa de cada vez.';
  end if;
  select * into t from trabalhos where id = m.trabalho;
  extra := greatest(0, m.nivel - t.nivel_min);
  pago  := round(t.salario / 6.0 * (1 + 0.06 * extra));
  ganho := greatest(1, round(t.xp / 5.0 * (1 + 0.04 * extra)));  -- XP por tarefa (era /6, /20, /10, /4)
  if t.id = 'pescador' then pago := 0; peixes_ganhos := (random() < 0.6)::integer; end if;
  novo_xp := m.xp + ganho;
  novo_nivel := nivel_de(novo_xp);
  if novo_nivel > m.nivel then
    select coalesce(sum(50 * g), 0) into premio from generate_series(m.nivel + 1, novo_nivel) g;
  end if;
  update moradores set dinheiro = dinheiro + pago + premio, xp = novo_xp, nivel = novo_nivel,
    peixes = peixes + peixes_ganhos, tarefa_em = now() where id = m.id;
  morreu := _gastar_fome(m.id, t.fome / 6.0);
  if morreu or (select fome from moradores where id = m.id) < 10 then
    cansado := true;
    update moradores set trabalho = null, trabalho_inicio = null, turnos = turnos + 1 where id = m.id;
  end if;
  return json_build_object('pago', pago, 'xp_ganho', ganho, 'subiu', novo_nivel - m.nivel, 'premio', premio,
    'peixes_ganhos', peixes_ganhos, 'morreu', morreu, 'cansado', cansado, 'eu', _estado(m.id));
end $$;
grant execute on function public.tarefa_feita() to authenticated;
