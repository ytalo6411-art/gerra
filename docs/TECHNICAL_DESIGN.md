# Arquitetura · Godot 4.4.1

| Área | Responsabilidade |
| --- | --- |
| `scenes/valley.tscn`, `scripts/valley.gd` | Cena principal e composição de uma sessão; junta entradas, relógio, UI, modelos e views. |
| `scripts/survivor.gd`, `scripts/view_rig.gd`, `scripts/controls.gd` | Corpo físico, animação procedural, câmera relativa aos controles, InputMap compartilhado. |
| `systems/catalog.gd`, `data/` | Manifesto autoral e catálogos JSON de itens e receitas. IDs estáveis, nome e apresentação separados da quantidade. |
| `systems/world_state.gd`, `systems/inventory.gd` | Estado serializável sem nós; necessidades em ticks ativos, seis slots, receita atômica, diário e modificações por ID. |
| `world/` | Terreno contínuo, loteamento da vegetação por setor, kit do posto e vistas descartáveis, retomadas a partir do estado. |
| `ui/`, `audio/` | HUD, mapa, ajuda e mochila. Ambiência e efeitos procedurais locais. |
| `systems/save_store.gd` | Principal, temporário e backup do slot versionado. |

## Streaming e interação

A geografia é fixa e os marcos têm coordenadas autorais; semente e funções determinísticas preenchem o relevo e os arredores. O setor atual e a vizinhança imediata somam até nove setores de 32 m. Depois da abertura, o setor atual tem prioridade e os vizinhos são acrescentados aos poucos. Um terreno grosseiro de fundo sem colisão cobre o horizonte. A física e os meshes dos setores removidos são descartados. Ao recriar uma vista, reaplique mudança registrada para porta, saque, coleta ou fogo.

Um raio no espaço físico limita a interação mais próxima a 3,1 m, sem atravessar paredes. A câmera A oculta telhado e paredes voltadas à câmera no interior; isso não desliga colisões. B encurta o braço diante de bloqueios. O terreno e cenário não dependem da renderização para simular inventário ou necessidades.

## Save e recuperação

- Autosave ao começar, em eventos significativos, a cada 25 s simulados e ao fechar normalmente a janela nativa quando há mudanças. **P** grava sob demanda. A aplicação não usa relógio de parede para avançar o mundo.
- Snapshot JSON (v1), verificado quanto a IDs e schema e envolto em checksum SHA-256 para detectar corrupção, não para autenticar. O temporário é fechado e relido. Um principal válido é copiado para um backup rotativo verificado. O temporário substitui o principal por renomeação no mesmo diretório.
- Recuperação na ordem principal, backup, temporário (se ambos anteriores falharem). Principal inválido nunca substitui backup bom. Se todos os candidatos falharem, o jogo preserva o registro e usa um espaço alternativo. Ainda não há migrações de schema nem promessa de durabilidade contra todo tipo de falha de energia/disco.
- A prévia Web usa o armazenamento local da origem (IndexedDB do template). A sincronização com o disco do navegador é assíncrona e depende da política do navegador ou iframe; não conte com gravação só no instante de fechar a aba. Use **P** e espere antes de sair. O save da prévia não é backup do jogo nativo.

## Perfil inicial

Compatibility, 720p sem MSAA, sombras direcionais de 1024 e curta distância, geometrias simples, materiais compartilhados e lotes MultiMesh. Um único ponto de luz pequeno aparece quando a fogueira está acesa. Sem partículas numerosas, SSAO, SSR, volumetria ou navegação ativa de NPCs. Esta estratégia não substitui medição de GPU.

Para novos assets: revisar licença **antes** de importar; registrar autor, fonte, versão e mudanças; testar GLB/glTF com escala de 1 m, pivô, colisão, material e leitura nas duas vistas; só adicionar ao preset após medir. Para produção, manter arquivos fontes pesados fora do pacote de runtime.
