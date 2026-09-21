<?php
/*
  PT-PT: Guarda de autenticacao para paginas de cliente.
         Exige sessao iniciada, sem exigir nivel de administrador. Incluir como
         PRIMEIRA instrucao da pagina, antes de qualquer HTML.

         Para o backoffice usar verificar_admin.php, que e mais restritivo.

  EN-UK: Authentication guard for customer pages.
         Requires a logged-in session, without requiring administrator level.
         Include as the FIRST statement of the page, before any HTML.

         For the backoffice use verificar_admin.php, which is stricter.
*/

if (session_status() !== PHP_SESSION_ACTIVE) {
    session_start();
}

if (empty($_SESSION['id_cliente']) || !isset($_SESSION['nivel_utilizador'])) {
    header('Location: index.php');
    exit;
}
