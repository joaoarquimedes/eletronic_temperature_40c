# Controlador de ventoinha por temperatura

Circuito analógico que liga uma ventoinha de 12 V quando a temperatura medida por um termistor NTC passa de um limite ajustável, e desliga quando ela volta a cair. Não usa microcontrolador: é um comparador LM393 com histerese acionando um Darlington TIP122.

O projeto é feito no **KiCad 10** e já vem preparado para simulação no **ngspice** (simulador integrado do KiCad), com modelos SPICE próprios para todos os componentes ativos.

| | Valor (ajuste atual) |
|---|---|
| Alimentação | 12 V DC |
| Liga a ventoinha em | ≈ 40 °C |
| Desliga a ventoinha em | ≈ 37 °C |
| Histerese | ≈ 3 °C |
| Corrente da ventoinha (simulada) | ≈ 250 mA |

> Os limites acima vêm da simulação (varredura de temperatura) e do cálculo do divisor. Na prática dependem da tolerância do termistor e da posição do trimpot.

## Como funciona

```
12 V ─ F1 ─┬─ C3/C1 ─┬─ U1 L7805 ─ +5 V ─┬─ R1 10k ─┬─ V_SENSOR ─► IN− ┐
           │         │                   │          └─ NTC 10k ─ GND   │ U2
           │         │                   └─ RV1 10k ─── V_REF ───► IN+ ┤ LM393
           │         │                                    ▲            │
           │         └─ R2 4,7k (pull-up) ───┬────────────┼─── OUT ◄───┘
           │                                 │         R3 120k (histerese)
           │                                 └─ R5 6,8k ─► base Q1 TIP122
           │
           └─ ventoinha (J3) + D1 1N4007 ─── coletor Q1 ─ emissor ─ GND
```

1. **Alimentação** – 12 V entram por J1, passam pelo fusível F1 (1 A) e são filtrados por C3 (220 µF) e C1 (100 nF). O L7805 (U1) gera 5 V estáveis para o sensor e para a referência.
2. **Sensor** – R1 (10 kΩ) e o NTC MF58 10 kΩ formam um divisor. Quanto mais quente, menor a resistência do NTC e menor a tensão `V_SENSOR`.
3. **Referência** – o trimpot RV1 define `V_REF` (≈ 1,77 V no ajuste atual), que corresponde à temperatura de disparo.
4. **Comparador** – quando `V_SENSOR` cai abaixo de `V_REF`, a saída em coletor aberto do LM393 fica solta e R2 a puxa para cima.
5. **Histerese** – R3 (120 kΩ) realimenta a saída em `V_REF`. Com a ventoinha ligada, `V_REF` sobe para ≈ 1,88 V, então é preciso esfriar alguns graus para desligar. Isso evita que a ventoinha fique ligando e desligando perto do limite.
6. **Acionamento** – a saída alimenta a base do TIP122 através de R5 (6,8 kΩ). O Darlington liga a ventoinha (J3), e D1 protege contra o pico de tensão do motor ao desligar.

A segunda metade do LM393 não é usada e tem as entradas presas em níveis fixos.

### Ajustando a temperatura de disparo

Gire o trimpot RV1 (na simulação, altere `pos` em *Sim.Params*):

- **aumentar** `pos` → `V_REF` menor → a ventoinha liga em temperatura **mais alta**;
- **diminuir** `pos` → `V_REF` maior → liga em temperatura **mais baixa**.

A histerese é definida principalmente por R3: um valor maior reduz a histerese, um valor menor aumenta.

## Estrutura do repositório

```
index/                      Projeto KiCad
├── index.kicad_pro         Projeto
├── index.kicad_sch         Esquema elétrico
├── index.kicad_pcb         Placa (ainda não iniciada)
├── index.wbk               Configuração do simulador (análises e sinais)
├── sym-lib-table           Bibliotecas de símbolos do projeto
└── fp-lib-table            Bibliotecas de footprints do projeto

lib/                        Modelos e bibliotecas próprias
├── Fuse/Fusivel_Sim.lib            Fusível 1 A (só resistência a frio)
├── L7805/
│   ├── Regulador_Sim.lib           Reguladores L7805, L7812 e AMS1117-3.3
│   ├── Regulador_Sim.kicad_sym     Símbolos com o modelo já associado
│   └── teste_L7805.cir             Teste avulso do modelo
├── LM393_SIM/
│   ├── Comparador_Sim.lib          Comparador duplo LM393
│   ├── LM393.kicad_sym             Símbolo do LM393 SOP-8 (LCSC C351428)
│   ├── C351428.pretty/             Footprint SOP-8
│   └── C351428.3dshapes/           Modelo 3D do SOP-8
├── Thermistor/
│   ├── Termistor_Sim.lib           NTC MF58 10k (equação Beta, B = 3950)
│   ├── Termistor_Sim.kicad_sym     Símbolos com o modelo já associado
│   └── teste_MF58.cir              Teste avulso do modelo
└── TIP122/Transistor_Sim.lib       Darlington TIP122
```

Todos os caminhos usam `${KIPRJMOD}/../lib/...`, então o projeto funciona em qualquer pasta, desde que `index/` e `lib/` fiquem lado a lado.

## Simulação

### No KiCad

1. Abra `index/index.kicad_pro` no KiCad 10.
2. No editor de esquema, abra **Inspecionar → Simulador**.
3. O arquivo `index.wbk` já traz as análises prontas:
   - **OP** – ponto de operação (tensões e correntes em repouso);
   - **DC TEMP 36 → 44 °C** – mostra o ponto em que a ventoinha liga;
   - **DC TEMP 44 → 32 °C** – mostra o ponto em que a ventoinha desliga.

   Os sinais observados são `V(/VENT)` (coletor do TIP122: baixo = ventoinha ligada) e `V(/V_SENSOR)`.

Alguns componentes existem só na simulação ou só na placa:

| Componente | Simulação | Placa / BOM | Papel |
|---|:-:|:-:|---|
| V1 (12 V) | ✓ | – | Substitui a fonte ligada em J1 |
| TH1-MF58 | ✓ | – | Representa a sonda ligada em J2 |
| R4 (48 Ω) | ✓ | – | Representa a ventoinha ligada em J3 (≈ 250 mA) |
| J1, J2, J3 | – | ✓ | Conectores da fonte, do sensor e da ventoinha |

### Testes avulsos dos modelos

Os arquivos `.cir` incluem a biblioteca por caminho relativo, então rode-os de dentro da pasta deles:

```bash
cd lib/Thermistor && ngspice teste_MF58.cir
cd lib/L7805      && ngspice teste_L7805.cir
```

## Limitações dos modelos

Os modelos são simplificados e usam valores típicos de datasheet, não medidos. Cada arquivo `.lib` descreve no cabeçalho o que não modela. Os pontos principais:

- **Varredura `.dc TEMP`** altera a temperatura de *todo* o circuito (TIP122 e diodos também), não só do sensor. Para variar apenas o NTC, use o subcircuito `MF58_10K_TC` com `.step param`.
- **NTC** – sem autoaquecimento nem constante de tempo térmica. Confira o valor de B da sua sonda.
- **Fusível** – só a resistência a frio; não simula a queima.
- **Regulador e comparador** – sem resposta em frequência, atraso de propagação nem proteção térmica.
- **D1** usa um modelo de diodo genérico do ngspice, não um modelo específico do 1N4007.

## Situação do projeto

- [x] Esquema elétrico
- [x] Modelos SPICE e simulação do ponto de disparo
- [ ] Atribuição de footprints
- [ ] Layout da placa (PCB)
