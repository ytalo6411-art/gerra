# Procedência e licenças

Revisão: **18/11/2026**. Nenhum mapa, áudio ou modelo de jogo comercial foi importado.

| Asset | Fonte / autoria | Licença | Integração |
| --- | --- | --- | --- |
| `assets/fonts/Barlow-Regular.ttf` | The Barlow Project Authors · [Google Fonts / Barlow](https://github.com/google/fonts/tree/main/ofl/barlow), blob `bb3faec4e243e812b288fbfb9235b12ea781eee4` | SIL OFL 1.1; [texto incluído](assets/fonts/OFL.txt) | Binário não modificado; textos gerais da interface. |
| `assets/fonts/BarlowCondensed-Bold.ttf` | The Barlow Project Authors · [Google Fonts / Barlow Condensed](https://github.com/google/fonts/tree/main/ofl/barlowcondensed), blob `9e480f467d703009e3abfce290b2ec2b7d24e188` | SIL OFL 1.1; a fonte traz o mesmo OFL | Binário não modificado; títulos e sinais da HUD. |
| Terreno, vegetação, casa, ponte, galpão, mobiliário, figura, efeitos e iconografia | Geometria e código original em `world/`, `scripts/survivor.gd`, `ui/glyph.gd`, `audio/field_sound.gd` | Conteúdo do próprio projeto; nenhuma licença de terceiros adicionada para esses componentes | Arte, animação e som de protótipo, não arte de produção. |

O motor [Godot 4.4.1](https://github.com/godotengine/godot/tree/4.4.1-stable) é MIT, com avisos adicionais para dependências do motor. As distribuições do motor devem acompanhar esses avisos. A prévia temporária da Arena usa o runtime Web oficial 4.4.1 (`49a5bc7b6`), recuperado de uma cópia pública versionada em [`beasaltfish/nexus-node-runner`](https://github.com/beasaltfish/nexus-node-runner/tree/main/builds/web) porque o sandbox não baixava os releases diretamente. Apenas JS/WASM do motor; nenhum PCK, imagem ou código de jogo desse repositório foi usado. `GODOT_LICENSE.txt` e `GODOT_COPYRIGHT.txt` acompanham a prévia. Para reproduzir a exportação fora da Arena, use o template oficial correspondente à sua versão do editor.
