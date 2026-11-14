-- ZERAR PROGRESSO (mantém as contas, os nomes e o visual dos personagens)
-- Zera: dinheiro, XP, nível, VIP, pets, carros, casas, vagas, empregos, ranking.
-- Não dá para desfazer.
update public.moradores set
  dinheiro = 100, xp = 0, nivel = 1, fome = 100, fome_em = now(),
  carros = '{}', carro = null, casa_id = null,
  trabalho = null, trabalho_inicio = null, turnos = 0,
  peixes = 0, mortes = 0, sinuca_em = null, tempo_jogo = 0, tempo_em = null,
  vip_ate = null, pets = '{}', pet = null;
update public.casas set dono = null, comprada_em = null, aberta = false;
update public.vagas set morador = null, carro = null, desde = null;
delete from public.frutas;
