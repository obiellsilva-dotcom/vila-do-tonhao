-- RESET TOTAL: apaga TODOS os personagens (nomes, visual, dinheiro, XP, ranking, VIP, pets,
-- carros, casas, posts, seguidores, chat e pedidos). Não dá para desfazer.
-- As contas de login (e-mail e senha) continuam: quem entrar de novo cria um personagem novo.
delete from public.moradores;
update public.casas set dono = null, comprada_em = null, aberta = false;
update public.vagas set morador = null, carro = null, desde = null;
