-- Novidades: nível máximo 50, carros 20% mais caros e oficina para personalizar o carro. Rode no Supabase (SQL Editor > New query > Run).

-- ===================== ETAPA 12: nível máximo 50 =====================
create or replace function public.nivel_de(p_xp integer) returns integer
language plpgsql immutable as $$
declare n integer := greatest(1, floor((1 + sqrt(1 + 4.0 * greatest(p_xp, 0) / 25)) / 2)::integer);
begin
  while public.xp_do_nivel(n + 1) <= p_xp loop n := n + 1; end loop;
  while n > 1 and public.xp_do_nivel(n) > p_xp loop n := n - 1; end loop;
  return least(n, 50);  -- nível máximo
end $$;

-- quem estava travado no 20 sobe conforme o XP que já tem
update public.moradores set nivel = public.nivel_de(xp) where public.nivel_de(xp) > nivel;

-- confere: quantos jogadores em cada nível
select nivel, count(*) as jogadores from public.moradores group by nivel order by nivel desc;

-- ===================== ETAPA 13: carros 20% mais caros =====================
update public.loja set preco = 2200 where id = 'moto' and tipo = 'carro';
update public.loja set preco = 3600 where id = 'fusca' and tipo = 'carro';
update public.loja set preco = 6600 where id = 'kombi' and tipo = 'carro';
update public.loja set preco = 14400 where id = 'opala' and tipo = 'carro';
update public.loja set preco = 30000 where id = 'caminhonete' and tipo = 'carro';
update public.loja set preco = 54000 where id = 'sedan' and tipo = 'carro';
update public.loja set preco = 84000 where id = 'jipe' and tipo = 'carro';
update public.loja set preco = 144000 where id = 'esportivo' and tipo = 'carro';

-- ===================== ETAPA 14: oficina (personalizar o carro) =====================
alter table public.moradores add column if not exists carro_mods jsonb not null default '{}'::jsonb;

-- preços iguais aos do jogo; só paga o que mudou
create or replace function public.personalizar_carro(p_carro text, p_cor text, p_roda integer, p_vidro integer, p_pintura integer, p_som boolean) returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores; at jsonb; custo integer := 0;
  pr_roda integer[] := array[0,2000,4000,8000,3000]; pr_vidro integer[] := array[0,800,1500,2500]; pr_pint integer[] := array[0,2500,4000,6000];
begin
  m := _eu();
  if not (p_carro = any(m.carros)) then raise exception 'Esse carro não é seu.'; end if;
  if p_roda not between 0 and 4 or p_vidro not between 0 and 3 or p_pintura not between 0 and 3 then raise exception 'Opção inválida.'; end if;
  if p_cor is not null and p_cor !~ '^#[0-9a-fA-F]{6}$' then raise exception 'Cor inválida.'; end if;
  at := coalesce(m.carro_mods->p_carro, '{}'::jsonb);
  if p_cor is not null and p_cor is distinct from (m.carro_cores->>p_carro) then custo := custo + 1000; end if;
  if p_roda <> coalesce((at->>'roda')::int, 0) then custo := custo + pr_roda[p_roda + 1]; end if;
  if p_vidro <> coalesce((at->>'vidro')::int, 0) then custo := custo + pr_vidro[p_vidro + 1]; end if;
  if p_pintura <> coalesce((at->>'pintura')::int, 0) then custo := custo + pr_pint[p_pintura + 1]; end if;
  if p_som and not coalesce((at->>'som')::boolean, false) then custo := custo + 5000; end if;
  if m.dinheiro < custo then raise exception 'Dinheiro insuficiente.'; end if;
  update moradores set dinheiro = dinheiro - custo,
    carro_cores = case when p_cor is null then carro_cores else carro_cores || jsonb_build_object(p_carro, p_cor) end,
    carro_mods = carro_mods || jsonb_build_object(p_carro, jsonb_build_object('roda', p_roda, 'vidro', p_vidro, 'pintura', p_pintura, 'som', coalesce(p_som, false)))
  where id = m.id;
  return json_build_object('custo', custo, 'eu', _estado(m.id));
end $$;
grant execute on function public.personalizar_carro(text, text, integer, integer, integer, boolean) to authenticated;

-- quem vende o carro perde a personalização dele
create or replace function public._limpa_mods() returns trigger language plpgsql as $$
begin
  new.carro_mods := coalesce((select jsonb_object_agg(k, v) from jsonb_each(new.carro_mods) e(k, v) where k = any(new.carros)), '{}'::jsonb);
  return new;
end $$;
drop trigger if exists limpa_mods on public.moradores;
create trigger limpa_mods before update of carros on public.moradores for each row execute function public._limpa_mods();

select nome, preco from public.loja where tipo = 'carro' order by preco;
