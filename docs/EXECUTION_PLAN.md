# Plano de execução · Fases 0 e 1

## Auditoria inicial — 18/11/2026

- Branch de trabalho `arena/95888637-gerra`, base `67b6c03`. O repositório continha apenas um `README.md`; não havia funcionalidades ou assets a migrar.
- Sandbox Debian 12 x86-64, 2 CPUs Xeon virtuais, cerca de 3,8 GiB de RAM, sem GPU exposta (`/dev/dri` ausente), sem sessão gráfica, sem Godot ou Blender instalados. Não é a máquina de referência.
- Base escolhida: Godot 4.4.1 estável, GDScript, renderer Compatibility, 1280 × 720 e preset baixo. A execução nativa no Acer continua sendo um portão de validação. A rede/contas não fazem parte do jogo.

## Sequência

| Etapa | Entrega | Evidência esperada |
| --- | --- | --- |
| 0a | Projeto Godot, convenções, licenças e bloco visual de uma clareira | Projeto abre sem dependências de gameplay externas |
| 0b | Câmeras A (3/4) e B (terceira pessoa), mesma cena e controles | Comparação com troca instantânea e rota repetível |
| 1a | Vale de teste 256 × 256 m, colisões, casa, galpão, curso d’água e setores | Atravessar fronteira de setor e retornar sem perder alterações |
| 1b | Coleta, mochila, água, fome/sede, fogueira e refúgio | Loop do diário reproduzível sem inventário duplicado |
| 1c | Save local versionado, troca segura, backup e recarga | Vinte ciclos isolados, dados inválidos e interrupção simulada |
| Validação | Registrar resultados e pedir escolha da câmera | Teste em hardware real antes de fixar arte/câmera ou ampliar o mundo |

As posições de marcos são autorais. Terreno, vegetação e malhas são gerados localmente com semente fixa para o benchmark. Água potável, receita de fogueira e uso do abrigo são antecipações pequenas do loop da seção 24, não uma implementação da Fase 2 inteira. O mapa de 16 km², ecossistema, agricultura, comunidades e sistemas extensos ficam fora desta iteração. Acompanhar o estado de cada entrega no README e no plano de testes.
