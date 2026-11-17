-- ETAPA 28, parte 3 de 9. Rode em ordem (1, 2, 3...). Se pedir, toque no botão verde.
create or replace function public.erro_tarefa() returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores; multa integer;
begin
  m := _eu();
  if m.trabalho is null or m.trabalho = 'pescador' then return json_build_object('multa', 0, 'eu', _estado(m.id)); end if;
  multa := least(25, m.dinheiro);
  update moradores set dinheiro = dinheiro - multa where id = m.id;
  return json_build_object('multa', multa, 'eu', _estado(m.id));
end $$;
revoke execute on function public.erro_tarefa() from public, anon;
grant execute on function public.erro_tarefa() to authenticated;

create or replace function public._pontos_tarefa(p_job text) returns integer
language sql immutable as $$
  select case p_job
    when 'bar' then 2
    when 'posto' then 2
    when 'concessionaria' then 2
    when 'barbearia' then 2
    when 'pescador' then 2
    when 'mercadinho' then 3
    when 'oficina' then 3
    when 'prefeito' then 3
    when 'banco' then 4
    when 'delegado' then 4
    when 'gerente' then 6
    when 'lixeiro' then 7
    when 'enfermeiro' then 8
    when 'padaria' then 8
    when 'medico' then 9
    when 'fabrica' then 12
    when 'prefeitura' then 15
    else 3 end
$$;
revoke execute on function public._pontos_tarefa(text) from public, anon;

create or replace function public._passe_pontos(p_morador uuid, p_pontos integer) returns void
language plpgsql security definer set search_path = public as $$
declare t text := _temporada_atual(); vip boolean;
begin
  if t is null then return; end if;
  select coalesce(vip_ate > now(), false) into vip from moradores where id = p_morador;
  insert into passe_jogador(morador, temporada, pontos) values (p_morador, t, least(6000, case when vip then round(p_pontos * 1.5) else p_pontos end))
  on conflict (morador, temporada) do update set pontos = least(6000, passe_jogador.pontos + case when vip then round(p_pontos * 1.5) else p_pontos end);
end $$;
revoke execute on function public._passe_pontos(uuid, integer) from public, anon, authenticated;
revoke execute on function public._temporada_atual() from public, anon;

create or replace function public.meu_passe() returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores; t public.passe_temporadas; j public.passe_jogador;
begin
  m := _eu();
  select * into t from passe_temporadas where id = _temporada_atual();
  if t.id is null then return json_build_object('temporada', null); end if;
  select * into j from passe_jogador where morador = m.id and temporada = t.id;
  return json_build_object('temporada', t.id, 'nome', t.nome, 'fim', t.fim, 'pontos', coalesce(j.pontos, 0),
    'premium', coalesce(j.premium, false), 'resgatados', coalesce(j.resgatados, '{}'),
    'premios', (select json_agg(json_build_object('nivel', nivel, 'trilha', trilha, 'premio', premio) order by nivel, trilha) from passe_premios where temporada = t.id));
end $$;
grant execute on function public.meu_passe() to authenticated;
