# Produto de Crédito - Informações Gerais

## Contexto do Mercado
- Mercado de crédito
- Equipe trabalhando desde o ano passado

### Desafios principais:
- Regulamentação BCEN
- Infraestrutura
- Novo produto em desenvolvimento
- Infraestrutura compartilhada com outros times

### Stakeholders
- **Originadores**: Empresas que antecipam recebíveis de crédito

---

## Responsabilidades da Infraestrutura
- Sustentação
- Monitoramento
- Incidentes
- Problemas
- Mudanças
- Melhorias

---

## Regulamentação
- Relacionamento com BCEN
- Regras e compliance
- Relacionamento com outros times, bancos e players

### Integração com BCEN / regulador — visão inicial (sem over-engineering)

- **Pensar cedo, integrar quando a norma e o canal estiverem fechados.** “BCEN” não é um único endpoint: são obrigações concretas (ex.: relatórios, cadastros, arranjos), cada uma com dado de origem, periodicidade e canal (API, arquivo, terceiro).
- **Base técnica que já ajuda:** dados financeiros exatos (centavos, sem `float` na persistência), trilha de operações/importações e modelo de gaps de compliance favorecem auditoria e explicabilidade antes de existir conector oficial.
- **Definir fronteira:** onde fica a responsabilidade de “falar com o mundo regulatório” (ex.: Rails domínio vs NestJS compliance/gateway), para não refatorar tudo depois.
- **Evidência desde já:** correlacionar requisições/envios (id de correlação), timestamps, estados de envio (pending/sent/ack/failed), possibilidade de reprocessamento idempotente; guardar payload ou hash quando LGPD permitir.
- **Evitar agora:** client completo, certificados e homologação longa sem especificação jurídica/técnica fechada; duplicar regras de negócio no core — preferir **exportar** o que já é verdade no domínio.
- **Próximo passo leve:** matriz viva (obrigação → dados no produto → frequência → dono) + workshop curto com compliance listando 3–5 obrigações prioritárias para os próximos 12 meses.

### Gaps identificados:
| Área | Gaps |
|------|------|
| Conhecimento | • |
| Processo | • |
| Tecnologia | • |
| Pessoas | • |

---

## Operacional
- Operacionalização
- Relacionamento com originadores e clientes
- Relacionamento com outros times, bancos e players

### Gaps identificados:
| Área | Gaps |
|------|------|
| Conhecimento | • |
| Processo | • |
| Tecnologia | • |
| Pessoas | • |

---

## Segurança
- Segurança da informação
- Segurança operacional
- Segurança de dados
- Segurança de pessoas

### Gaps identificados:
| Área | Gaps |
|------|------|
| Conhecimento | • |
| Processo | • |
| Tecnologia | • |
| Pessoas | • |

---

## Qualidade
- Qualidade do produto
- Qualidade do processo
- Qualidade da equipe

---

## Stack Tecnológico
| Tecnologia | Descrição |
|------------|----------|
| **AWS** | Cloud infrastructure |
| **Next.js** | Frontend framework |
| **Rails** | Backend (Ruby on Rails) |
| **NestJS** | Backend (Node.js) |
| **Node.js** | Backend runtime |
| **PostgreSQL** | Banco de dados relacional |
| **Redis** | Banco de dados em memória / cache |

---

## IA / análise de risco assistida (futuro)

- **Intenção:** avaliar **ruby_llm** (ou stack equivalente) para **apoio** à análise de risco de investimentos — copiloto, rascunhos e leitura assistida; **não** substitui modelo de crédito nem decisão regulatória automática.
- **Quando:** **depois** de termos o **front em Next.js** (UX, fluxos, revisão humana). **Por ora:** só esta direção documentada; **sem** gem no POC Rails nem integração ativa.

---

## Próximos Passos
- [ ] Avaliar gaps identificados
- [ ] Planejar melhorias na infraestrutura
- [ ] Desenvolver novo produto
- [ ] Fortalecer compliance com BCEN
- [ ] Elaborar matriz obrigação → dados → frequência → canal (integração regulatória)
- [ ] Workshop compliance: 3–5 obrigações BCEN/regulador prioritárias (12 meses)
- [ ] (Após Next.js) Explorar IA assistiva para análise de risco (ex.: ruby_llm + API Rails consumida pelo front)
