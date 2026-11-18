# Guia do protótipo · Primeiro refúgio

O documento mestre de 18/11/2026 segue como referência da produção. Este recorte testa se o vale pode ser lido, explorado e reencontrado depois de salvar. Não fixa a câmera nem define o volume de conteúdo do jogo final.

## Experiência jogável

1. Chegue pela trilha sul. O diário marca a bomba ao lado da cabana. Encha o cantil, depois use a porção na barra.
2. Colete os dois feixes à esquerda da trilha (2 + 1 galhos), ou explore a margem. A fogueira já está delimitada com pedras e exige três galhos.
3. Na cabana, abra a porta e pegue comida no caixote, ou use as amoras sinalizadas na borda da clareira. Coma uma porção.
4. Prepare a cama de campanha. Salve com **P** para concluir o diário. É possível continuar a explorar depois disso.

Saciedade e hidratação caem gradualmente. A corrida consome energia e acelera o desgaste. A morte por privação extrema encerra o personagem; o sucessor começa sem a mochila anterior, mas o estado da clareira e o diário seguem no mesmo mundo. Ainda não há corpos recuperáveis nem regeneração de coleta: uma partida longa pode esgotar as provisões, inclusive se perder materiais na morte. Abrigo e fogueira recuperam energia; sono, temperatura, preparo de água e culinária têm seus próprios marcos posteriores.

## Mini Art Bible

- **Solo:** verde sálvia e oliva sob a copa; barro acastanhado e mais quente na trilha; cascalho claro na margem. A cor marca o material e não depende de filtro global.
- **Casa:** kit de tábuas, vãos, molduras, telhado metálico de duas águas e chaminé. Lógica em módulos, enquadramento de fibras e tábuas visível em terceira pessoa, sem fazer personagens ou vegetação em voxels. O galpão tem cobertura simples e uso limitado.
- **Árvore:** tronco afunilado, copa silvestre assimétrica ou cedro afunilado em camadas. Cerejeiras/amoreiras não compartilham a silhueta de um pinheiro; o arbusto coletável tem frutos matizados.
- **Animal (conceito para a etapa seguinte, sem modelo incluído):** cão vira-lata de porte médio, tronco mais comprido que alto, focinho visível em ¾, orelhas assimétricas e anatomia orgânica. Testar um só rig e legibilidade de farejar, andar e sentar antes de variar portes.
- **Iluminação e som:** uma luz natural com sombras seletivas, névoa leve, sem iluminação global dinâmica. O vento e os efeitos procedurais são provisórios, não biblioteca final.

## Decisões abertas

| Questão | O que experimentar no mesmo lugar | Não travar antes de |
| --- | --- | --- |
| **Câmera A ou B?** | Caminhar da trilha à ponte; procurar o feixe no solo; entrar na cabana, achar a caixa e a cama. A é ortográfica elevada com recorte visual; B é perspectiva com braço que encurta diante de paredes. Use `C` para trocar. | Comparar leitura do terreno, obstáculos e escala, conforto dentro da cabana e desempenho em 720p. |
| **O que deve parecer “quadrado”?** | Separar o kit de arquitetura/grade lógica dos personagens orgânicos. O cenário de teste não implementa encaixe de construção. | Confirmar se a referência era a organização espacial e não personagens cúbicos. |
| **Meta técnica da fatia** | Medir as duas câmeras no Acer em baixo: abertura, trilha e interior. | Registrar frame time, RAM de processo e estabilidade no driver real. |

Depois da validação, expandir sobrevivência e preparar o teste com um cão nomeado e interativo. Não produzir raças, NPCs nem setores em massa antes de confirmar a base.
