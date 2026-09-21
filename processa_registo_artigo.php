<?php
/*
  PT-PT: Duplicado orfao de processar_registo_artigo.php (com "r").

         Nenhuma pagina do site enviava dados para aqui -- adicionar_artigo.php
         usa a outra grafia -- mas o ficheiro continuava acessivel por URL e
         aceitava envios de ficheiros com a mesma falha de execucao remota de
         codigo: o tipo era lido do cabecalho do cliente e o nome do ficheiro
         era usado tal e qual.

         O INSERT que aqui existia estava ainda partido: seis colunas para cinco
         valores, faltando preco_artigo, pelo que nunca chegou a funcionar. Mas
         o upload acontecia ANTES do INSERT, e por isso a falha era explorvel
         mesmo com a consulta a falhar.

         Em vez de manter duas copias da mesma logica de seguranca -- que com o
         tempo divergem, como ja tinham divergido -- este ficheiro passa a
         delegar no tratamento unico e endurecido.

  EN-UK: Orphaned duplicate of processar_registo_artigo.php (with the "r").

         No page posted here -- adicionar_artigo.php uses the other spelling --
         but the file stayed reachable by URL and accepted uploads with the same
         remote-code-execution flaw: the type was read from the client's header
         and the client's filename was used verbatim.

         Its INSERT was broken anyway: six columns against five values, missing
         preco_artigo, so it never worked. The upload happened BEFORE the
         INSERT, though, so the flaw was exploitable regardless.

         Rather than keep two copies of the same security logic -- which drift
         apart over time, as these already had -- this file now delegates to the
         single hardened handler.
*/
require __DIR__ . '/processar_registo_artigo.php';
