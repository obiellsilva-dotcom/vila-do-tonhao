-- ETAPA 28, parte 4 de 9. Rode em ordem (1, 2, 3...). Se pedir, toque no botão verde.
-- entrega um prêmio visual (roupa para os dois sexos, estampa) ou dinheiro do jogo
create or replace function public._dar_premio(p_morador uuid, p jsonb) returns void
language plpgsql security definer set search_path = public as $$
declare k text;
begin
  if p ? 'dinheiro' then update moradores set dinheiro = dinheiro + (p->>'dinheiro')::int where id = p_morador; end if;
  if p ? 'carro' then update moradores set carros = case when (p->>'carro') = any(carros) then carros else array_append(carros, p->>'carro') end where id = p_morador; end if;
  if p ? 'estampa' then insert into guarda_roupa(morador, peca, item) values (p_morador, 'estampa', (p->>'estampa')::int) on conflict do nothing; end if;
  if p ? 'rastro' then insert into guarda_roupa(morador, peca, item) values (p_morador, 'rastro', (p->>'rastro')::int) on conflict do nothing; end if;
  foreach k in array array['roupa','calca','calcado','chapeu','extra'] loop
    if p ? k then
      insert into guarda_roupa(morador, peca, item) values (p_morador, k || '_m', (p->k->>0)::int), (p_morador, k || '_f', (p->k->>1)::int) on conflict do nothing;
    end if;
  end loop;
end $$;
revoke execute on function public._dar_premio(uuid, jsonb) from public, anon, authenticated;

create or replace function public.resgatar_passe(p_nivel integer, p_trilha text) returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores; t text := _temporada_atual(); j public.passe_jogador; pr jsonb; cod text;
begin
  m := _eu();
  if t is null then raise exception 'Nenhuma temporada ativa agora.'; end if;
  select * into j from passe_jogador where morador = m.id and temporada = t for update;
  if j.morador is null or j.pontos < p_nivel * 300 then raise exception 'Você ainda não chegou nesse nível do passe.'; end if;
  if p_trilha = 'premium' and not j.premium then raise exception 'Esse prêmio é do Passe Premium.'; end if;
  cod := p_nivel || case when p_trilha = 'premium' then 'p' else 'g' end;
  if cod = any(j.resgatados) then raise exception 'Você já pegou esse prêmio.'; end if;
  select premio into pr from passe_premios where temporada = t and nivel = p_nivel and trilha = p_trilha;
  if pr is null then raise exception 'Prêmio não encontrado.'; end if;
  if pr ? 'carro' and not (select carro_pronto from passe_temporadas where id = t) then raise exception 'O carro exclusivo chega em breve!'; end if;
  perform _dar_premio(m.id, pr);
  update passe_jogador set resgatados = array_append(resgatados, cod) where morador = m.id and temporada = t;
  return json_build_object('premio', pr, 'eu', _estado(m.id));
end $$;
grant execute on function public.resgatar_passe(integer, text) to authenticated;

-- presente do mês do VIP (só quem está VIP naquele mês pega; fica para sempre)
create table if not exists public.vip_mensal (mes text primary key, premio jsonb not null);
insert into public.vip_mensal(mes, premio) values
  ('2026-11', '{"roupa":[14,12]}'), ('2026-12', '{"calca":[11,13]}'), ('2027-01', '{"roupa":[18,11]}'),
  ('2027-02', '{"estampa":10}'), ('2027-03', '{"calcado":[5,6]}'), ('2027-04', '{"chapeu":[8,6]}')
on conflict (mes) do update set premio = excluded.premio;
create table if not exists public.vip_presentes (
  morador uuid not null references public.moradores(id) on delete cascade, mes text not null, pego_em timestamptz not null default now(),
  primary key (morador, mes)
);
alter table public.vip_mensal enable row level security;
