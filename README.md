# NO WAY HOME · Vale do Cedro

**Protótipo jogável de sobrevivência 3D.** Seis meses depois da tempestade, você chega a um posto florestal vazio. O primeiro objetivo é conseguir água, comida e um lugar para passar a noite.

## Jogar

- **Na Arena:** abra a prévia **NO WAY HOME — Vale do Cedro**, clique em **Entrar na clareira** e siga o Diário de Campo. A prévia exige teclado e mouse, WebGL 2 e permite salvar localmente quando o navegador libera o armazenamento.
- **No Linux:** abra `project.godot` com **Godot 4.4.1** e pressione **F5** para rodar o projeto, ou execute `godot --path .`. Nenhum servidor é necessário no jogo nativo. O preset inicial é **Compatibility, baixo, 1280 × 720**. Para distribuir sem editor, instale os templates oficiais da sua versão do Godot e exporte o preset **Linux**.

| Ação | Controle |
| --- | --- |
| Andar / correr | `WASD` ou setas / `Shift` |
| Interagir com o objeto ao alcance | `E` ou clique no prompt |
| Usar uma porção da barra | `1`–`6` ou clique no slot |
| Mochila / mapa | `Tab` ou `I` / `M` |
| Alternar A ¾ e B terceira pessoa | `C` |
| Girar em passos de 45° / zoom | `Q` e `R` / roda do mouse |
| Salvar / pausar e fechar painéis | `P` / `Esc` |

**Primeiro refúgio:** encha o cantil na bomba e beba a porção; recolha três galhos e acenda a fogueira; abra a cabana ou encontre amoras e coma; prepare a cama da cabana e salve. Use o mapa para localizar a bomba e o próximo objetivo. O riacho é um marco de navegação, não uma fonte potável nesta etapa.

Os registros são locais. No Godot, use **Projeto → Abrir pasta de dados do usuário** para ver `vale_do_cedro_v1.json` e seu `.bak`. No navegador, o registro pertence àquela origem, perfil e dispositivo; não é compartilhado com a build nativa. A simulação para no menu, com os painéis de mapa/mochila e fora da sessão.

## Escopo desta entrega

- **Fase 0:** base Godot, clareira de benchmark e duas câmeras na mesma cena, sem decisão definitiva. Arte procedural de protótipo, com geometria e paleta próprias.
- **Fase 1:** terreno de teste de 256 × 256 m, setores de 32 m, uma cabana acessível, galpão, cercado, riacho e ponte; movimento e colisões, interações, mochila, quatro indicadores funcionais, diário e salvamento local validado. A receita de fogo e o uso da cama são o mínimo do loop, não toda a Fase 2.
- **Fora da entrega:** cão e criação de animais, agricultura, NPCs, clima/dia-noite, mundo final e conteúdo de produção. A câmera e a direção visual precisam de validação; o FPS e a memória de referência ainda precisam ser medidos no Acer.

## Construir e verificar

```sh
# Importação inicial; Godot 4.4.1 padrão
godot --headless --path . --editor --import
# Regressão isolada; não toca no registro da partida
godot --headless --fixed-fps 60 --path . --script res://tests/checks.gd
# Benchmark gráfico nativo: execute em uma sessão com vídeo, não headless
godot --path . --resolution 1280x720 -- --benchmark=A --benchmark-seconds=60
godot --path . --resolution 1280x720 -- --benchmark=B --benchmark-scenario=interior --benchmark-seconds=60
```

Para gerar uma prévia reproduzível com os templates oficiais:

```sh
mkdir -p build/web
godot --headless --path . --export-release Web build/web/index.html
python3 tools/serve_preview.py
```

- [Plano e auditoria](docs/EXECUTION_PLAN.md)
- [Escopo, arte e decisões](docs/DESIGN.md)
- [Arquitetura e políticas de save](docs/TECHNICAL_DESIGN.md)
- [Reprodução dos testes e resultados](docs/TEST_PLAN.md)
- [Procedência e licenças](ASSET_CREDITS.md)
