<?php
//iniciar sessao
session_start();
//destruir sessao
session_destroy();
//enviar o utilizador para a pagina de autenticaçao
header('Location: index.php');
?>