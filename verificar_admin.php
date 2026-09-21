<?php
/*
  PT-PT: Guarda de autorizacao para as paginas de administracao.
         Incluir como PRIMEIRA instrucao de cada pagina de admin, antes de
         qualquer HTML -- depois de o PHP enviar output ja nao e possivel
         redireccionar com header().

         O nivel 1 e administrador; o nivel 2 e cliente. Um cliente autenticado
         nao pode chegar ao backoffice.

  EN-UK: Authorisation guard for the administration pages.
         Include it as the FIRST statement of every admin page, before any
         HTML -- once PHP has sent output, header() can no longer redirect.

         Level 1 is administrator; level 2 is a customer. An authenticated
         customer must not reach the backoffice.
*/

if (session_status() !== PHP_SESSION_ACTIVE) {
    session_start();
}

$autenticado = !empty($_SESSION['id_cliente']);
$e_administrador = isset($_SESSION['nivel_utilizador'])
    && (int) $_SESSION['nivel_utilizador'] === 1;

if (!$autenticado || !$e_administrador) {
    // PT-PT: Sem pistas sobre o motivo -- nao dizer se faltou sessao ou nivel.
    // EN-UK: No hint as to why -- do not reveal whether it was session or level.
    header('Location: index.php');
    exit;
}
