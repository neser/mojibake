# corrigir.sh

Script Bash para corrigir nomes de arquivos com acentuação quebrada (mojibake) em uploads do WordPress.  
Ele cria **cópias** de PDFs e XLSX com os nomes corrigidos (acentos e caracteres especiais), sem alterar os arquivos originais nem o banco de dados.

## Funcionalidades
- Corrige padrões comuns de mojibake em português (ex.: `vota‡ֶo` → `votação`, `DEMONSTRA€åES` → `DEMONSTRAÇÕES`).
- Funciona apenas na pasta atual (não recursivo).
- Mantém os originais intactos.
- Gera log `.csv` com todas as operações realizadas.
- Suporte a arquivos `.pdf` e `.xlsx`.

## Uso

No diretório onde estão os arquivos problemáticos (ex.: `/wp-content/uploads/2025/08`):

```bash
# dar permissão de execução
chmod +x ./corrigir.sh

# simulação (não cria nada, só mostra)
./corrigir.sh --dry

# executar
./corrigir.sh
