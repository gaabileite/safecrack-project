# SafeCrack Pro

[English](README.en.md) · **Português**

Cofre digital em SystemVerilog para a placa Altera **DE2-115**. A senha de quatro dígitos (0–9) é composta um dígito por vez com push buttons e verificada por uma máquina de estados finita (FSM); o resultado é sinalizado pelos LEDs.

Projeto da disciplina CIN0130 — Sistemas Digitais (CIn/UFPE, 2026.1), professor Victor Medeiros.

## Vídeo

[Assista ao vídeo do projeto no YouTube](https://youtu.be/_vgWMApheu0?si=FNMOXqHvSTn_HW01).

## Estrutura do repositório

```
.
├── rtl/
│   ├── safecrackpro_top.sv         # top-level: pinos, FSM e decodificadores
│   ├── safecrack.sv                # FSM: edição, verificação e LEDs
│   └── bcd_to_7segment_anodo.sv    # decodificador BCD -> 7 segmentos
├── README.md
└── README.en.md
```

## Funcionamento

O sistema mantém quatro registradores de 4 bits (`register3`–`register0`), exibidos em **HEX3–HEX0**. O display **HEX4** mostra o índice (1–4) do dígito em edição.

| Botão    | Porta      | Função                                  |
|----------|------------|-----------------------------------------|
| `KEY[3]` | `btn_inc`  | Incrementa o dígito ativo (9 → 0)       |
| `KEY[2]` | `btn_dec`  | Decrementa o dígito ativo (0 → 9)       |
| `KEY[1]` | `key_conf` | Confirma o dígito e avança              |
| `KEY[0]` | `rst`      | Reset                                   |

Fluxo de uso:

1. Em cada posição, ajuste o valor com incremento/decremento e confirme com `key_conf`.
2. Os dígitos são editados em ordem, do HEX3 ao HEX0. Não há retorno a um dígito já confirmado; para corrigir, use o reset.
3. Ao confirmar o quarto dígito, a senha é comparada com a configurada:
   - **correta**: LEDs verdes (`LEDG`) acesos por 5 s;
   - **incorreta**: LEDs vermelhos (`LEDR`) acesos por 3 s.
4. Terminado o tempo, o sistema volta ao estado inicial.

### Senha

A senha é fixada em tempo de síntese pelas constantes `pass0`–`pass3` em `rtl/safecrack.sv`, comparadas com `register0`–`register3`. Com os valores atuais, os displays HEX3 → HEX0 devem mostrar **9 · 3 · 7 · 2** para o acerto.

## Arquitetura

| Módulo                  | Responsabilidade |
|-------------------------|------------------|
| `safecrackpro_top`      | Liga a FSM às portas físicas e instancia cinco decodificadores de 7 segmentos. |
| `safecrack`             | FSM com codificação *one-hot* (16 estados): edição por dígito (`A`–`D` e estados auxiliares `*_INC`/`*_DEC`), `CHECK`, `CORRECT`, `WRONG` e `WAIT`. |
| `bcd_to_7segment_anodo` | Decodifica BCD (0–9) para 7 segmentos de ânodo comum, ativos em nível baixo; valores inválidos exibem um hífen. |

Decisões de projeto:

- **Uma ação por clique.** Cada botão passa por um detector de borda (o `KEY` é invertido e comparado ao valor do ciclo anterior), então manter o botão pressionado não repete a ação.
- **Edição em um ciclo.** Os estados `*_INC`/`*_DEC` duram um ciclo de clock, alteram só o registrador do dígito ativo e voltam ao estado pai, com *wrap-around* explícito.
- **Temporização.** `WAIT` decrementa `delay_cnt`, carregado com `5 × ONE_SECOND` ou `3 × ONE_SECOND`. `ONE_SECOND` vale `50_000_000` (clock de 50 MHz) e é uma constante local de `safecrack`; para simular, reduza-a no código.
- **Resultado persistente.** O flag `was_correct` mantém a cor correta dos LEDs durante todo o `WAIT`.

## Diagrama de estados

O estado `WAIT` foi adicionado depois deste diagrama, que é a primeira versão feita em sala. O reset leva qualquer estado a `A` e foi omitido para facilitar a leitura.

<img width="1147" height="740" alt="Diagrama de estados da FSM" src="https://github.com/user-attachments/assets/aa8b43a0-6a1a-4b2f-88b2-58997d26d804" />

## Pinagem (DE2-115)

Entradas:

| Porta      | Sinal na placa | Pino      |
|------------|----------------|-----------|
| `clk`      | `CLOCK_50`     | `PIN_Y2`  |
| `rst`      | `KEY[0]`       | `PIN_M23` |
| `key_conf` | `KEY[1]`       | `PIN_M21` |
| `btn_dec`  | `KEY[2]`       | `PIN_N21` |
| `btn_inc`  | `KEY[3]`       | `PIN_R24` |

Saídas (atribua aos pinos conforme o `.qsf` padrão da DE2-115, que não faz parte do repositório):

| Porta         | Sinal na placa            |
|---------------|---------------------------|
| `seg_pos4`    | `HEX3` (primeiro dígito)  |
| `seg_pos3`    | `HEX2`                    |
| `seg_pos2`    | `HEX1`                    |
| `seg_pos1`    | `HEX0` (último dígito)    |
| `seg_cur_pos` | `HEX4` (dígito ativo)     |
| `led_red`     | `LEDR[17:0]`              |
| `led_green`   | `LEDG[8:0]`               |

## Simulação

O testbench usado na disciplina (`safecrack_tb.sv`) não está neste repositório. Ele exercitava dois cenários — senha incorreta (LEDs vermelhos) e correta (LEDs verdes), com um *wrap-around* 0 → 9 — com `ONE_SECOND` reduzido para 5. A forma de onda abaixo é o resultado dessa simulação.

<img width="1843" height="284" alt="Forma de onda da simulação" src="https://github.com/user-attachments/assets/2b122b17-8163-453d-89e0-ad93b2a580b0" />

Para reproduzir no [EDA Playground](https://edaplayground.com), cole `rtl/safecrack.sv` em *design.sv* e o testbench em *testbench.sv*, escolha um simulador SystemVerilog, marque *Open EPWave after run* e execute.

## Compilação e gravação

No Quartus Prime:

1. Crie um projeto para o dispositivo da DE2-115 (Cyclone IV E, `EP4CE115F29C7`).
2. Adicione os arquivos de `rtl/` e defina `safecrackpro_top` como entidade top-level.
3. Importe as atribuições de pinos da DE2-115 e associe as portas conforme a tabela acima.
4. Compile e grave o `.sof` pelo *Programmer*.

## Limitações conhecidas

- **Polaridade do reset.** O bloco sequencial usa `posedge rst`, ou seja, reset ativo em nível alto, enquanto os `KEY` da DE2-115 são ativos em nível baixo. Na placa, o reset só tem o efeito esperado se o sinal for invertido antes de chegar à FSM.
- **Sem sincronizador.** Os botões são amostrados diretamente, sem sincronizador de dois flip-flops, o que deixa um risco teórico de metaestabilidade. Na prática os `KEY` da DE2-115 têm tratamento de *bounce* em hardware.
- **Índice base 1.** O HEX4 exibe `position + 1` (1–4). Para a faixa 0–3, remova o incremento na instanciação do decodificador em `safecrackpro_top`.
- **Sem navegação para trás.** É intencional e segue a especificação; a correção é feita pelo reset.
