# artificial-intelligence-reactive-agents

## esboco texto para o relatório

- Modelo Básico

    No modelo básico os agentes procuram sobreviver o máximo de tempo possível, para que o mesmo aconteça , precisam de se alimentar , evitar armadilhas , utilizar os abrigos ( no caso dos expert ) a seu favor , tudo isto para manter o nível de energia acima de zero.
    Este modelo consta com 2 agentes, os basic e os expert , que lutam entre eles para a manutenção da sua energia. Os agentes expert percecionam dois tipos de alimento ( verde e amarelo) enquanto que os agentes basic só percecionam o alimento amarelo.
    Existem ainda mais dois elementos no ambiente, as armadilhas e os abrigos. São ambos percecionados pelos agentes mas , cada um dos agentes vai ter um comportamento diferente.





- Comportamento dos Agentes


    No caso dos Basic , estes percecionam para a frente e para a sua direita. Procuram encontrar comida do tipo amarelo , evitar armadilhas. Mas mesmo conseguindo , em certas condições, absorver energia dos agentes expert , tende a ser mais favorável evitar os mesmos.

    Já os Expert , percecionam para a esquerda , frente e direita. Procuram encontrar comida do tipo amarelo e verde , evitar armadilhas e refugiarem-se nos abrigos para a recuperação de energia e obtenção de experiencia.


    Os Agentes Expert ao contrário dos Basic possuiem memória , permitindo aos mesmos usufruir do sistema de experiencia que foi implementado neste modelo. Quando o agente ingere "X" alimentos , obtem uma quantidade de experiencia predefinida dependendo do tipo de alimento.





    - Modelo Básico  ( conclusão)

    Neste primeiro modelo, podemos verificar que o ambiente e as condições aplicadas aos agentes do tipo basic , fazem com que os agentes do tipo Expert tenham uma esperança de vida substancialmente superior.