# Testes da Fase 0/1

## Regressão automática

```sh
godot --headless --fixed-fps 60 --path . --script res://tests/checks.gd
```

A suíte devolve código diferente de zero se uma verificação falhar. Não usa o slot normal. Exercita a cena principal e suas colisões reais, além de:

- Seis slots, divisão por stack, mochila cheia, transações atômicas de receita e consumo sem duplicação.
- Vinte ciclos de gravação e leitura, comparando necessidades, posição, inventário, câmera e objetos. Temporário incompleto com principal íntegro, backup com principal corrompido, temporário como única cópia, versão e quantidade inválidas.
- Caminhar, trocar entre A e B, pausar pela mochila, abrir o mapa, encher/beber água, coletar, acender o fogo, usar caixa e cama, salvar o diário.
- Porta fechada bloqueia entrada, porta aberta permite passar, parede impede acesso à caixa, recorte de telhado e travessia da ponte. Sair dos setores da clareira e voltar preserva porta, coleta e fogo; recriar a cena preserva o registro e não avança o relógio antes de continuar.
- Desidratação extrema e entrada de sucessor no mesmo mundo sem herdar a mochila anterior.

A interrupção de escrita é **simulada** com os estados dos arquivos relevantes; não foi feito teste de retirar energia da máquina.

## Roteiro manual com teclado e mouse

1. Entre e confira o diário de seis tarefas; use `M` para localizar a bomba. Com `E`, recolha água e use o slot ocupado com `1`–`6`. Compare com o botão da mochila. Tente acender o fogo antes de ter os três galhos e verifique a mensagem.
2. Recolha madeira, acenda o fogo, abra a porta e recolha/coma comida; prepare o abrigo. Com a câmera A, inspecione o recorte no interior e a leitura de chão. Troque para B no mesmo lugar e veja se a câmera se aproxima sem atravessar a parede.
3. Salve com `P`. Atravesse a ponte, vá além dos setores visíveis ou feche e reabra. Verifique diário, porta, posição, fogueira e itens. No navegador, aguarde a sincronização antes de recarregar.
4. Repita na máquina de referência sem o editor aberto para medir a build nativa.

## Benchmark no Acer (pendente)

Linux Mint, 1280 × 720, Compatibility / Baixo, sem editor. Rodar 60 s úteis, depois de 3 s de aquecimento, três vezes por câmera e cenário:

```sh
godot --path . --resolution 1280x720 -- --benchmark=A --benchmark-seconds=60
godot --path . --resolution 1280x720 -- --benchmark=B --benchmark-seconds=60
godot --path . --resolution 1280x720 -- --benchmark=A --benchmark-scenario=interior --benchmark-seconds=60
godot --path . --resolution 1280x720 -- --benchmark=B --benchmark-scenario=interior --benchmark-seconds=60
```

Na build nativa, substitua `godot --path .` pelo executável. Prefira `/usr/bin/time -v` ou um monitor externo para RSS máximo, porque `godot_static_mib` não é consumo total do processo. Registre Mesa/driver, FPS médio, P99/máximo em ms, contadores de renderização, etapas percorridas, tempo de carregamento e RSS, além de travadas. Verifique `waypoints`: não use como referência uma execução que não percorra a rota. `--economico` é apenas perfil de contingência (3D a 62%, sem sombras direcionais), não o benchmark padrão. A prévia Web ativa esse perfil se detectar, localmente, rasterização por software.

Meta, não garantia: buscar 30 FPS estáveis e aproximadamente 1,5–2,0 GiB de RAM de processo ou menos. Chuva leve e cinco entidades ativas ainda precisam de sistemas de marcos posteriores; não são simuladas por esta rota. A suíte headless não serve para inferir FPS.

## Execução neste repositório

- **Headless:** Godot 4.4.1 compilado dos fontes para o sandbox, com visualização dummy, completou **74 verificações sem falhas**. O binário mínimo registra que não tem renderizadores nem física 2D; isso é do binário de teste, não da configuração do projeto. A cena e a física 3D foram executadas.
- **Memória de teste:** pico de RSS **113,9 MiB** no processo Godot headless durante a regressão. Não inclui renderização nem uso do driver; não é orçamento verificado para a build gráfica.
- **Smoke WebGL:** Chromium em SwiftShader, sem GPU, dois vCPUs, trilha em 1280 × 720, 18 s por amostra útil. Contadores são os do motor (incluem passes de renderização). `estática` é `MEMORY_STATIC`, não RSS. O navegador não completou a rota; os números evidenciam que o perfil não é jogável nesse fallback de software, e não estimam o desempenho no Acer.

| Câmera / perfil | FPS médio | P99 / máximo | Draw calls / objetos (média) | Carga da cena | Memória estática | Waypoints |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| A · Baixo | 0,7 | 2.354 / 2.354 ms | 442 / 822 | 1.130 ms | 43,9 MiB | 1 |
| B · Baixo | 0,7 | 3.494 / 3.494 ms | 424 / 809 | 1.365 ms | 43,9 MiB | 1 |
| A · Econômico | 1,4 | 1.260 / 1.260 ms | 366 / 745 | 1.175 ms | 43,9 MiB | 2 |

A carga indicada começa em `_ready` e não inclui baixar/compilar o runtime WASM. Nenhuma medição de VRAM compartilhada ou conclusão de compatibilidade do driver do Acer foi feita.

**Persistência Web:** teste adicional em Chromium, viewport de 720 × 405 para interação no sandbox. Início por clique, navegação pelos painéis, troca A → B e `P`; o teste leu o snapshot no IndexedDB, recarregou a página e continuou a sessão na câmera B. Nenhum erro de script foi registrado nesse teste. Não houve tentativa de usar o FPS desse teste como benchmark de hardware.
