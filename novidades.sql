-- Novidades: nível máximo 50 e carros mais caros. Rode no Supabase (SQL Editor > New query > Run).

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

-- ===================== ETAPA 13: carros mais caros =====================
update public.loja set preco = 2500 where id = 'moto' and tipo = 'carro';
update public.loja set preco = 4000 where id = 'fusca' and tipo = 'carro';
update public.loja set preco = 7000 where id = 'kombi' and tipo = 'carro';
update public.loja set preco = 15000 where id = 'opala' and tipo = 'carro';
update public.loja set preco = 32000 where id = 'caminhonete' and tipo = 'carro';
update public.loja set preco = 58000 where id = 'sedan' and tipo = 'carro';
update public.loja set preco = 90000 where id = 'jipe' and tipo = 'carro';
update public.loja set preco = 150000 where id = 'esportivo' and tipo = 'carro';
select nome, preco from public.loja where tipo = 'carro' order by preco;
