<?php
//credenciais de acesso
$servidor="localhost";
$base_dados="Epalte_ONLINE";
$nome_administrador="root2";
$password_administrador="";
//ligacao 
$ligacao=mysql_connect($servidor, $nome_administrador, $password_administrador)or die('Erro de ligacao à base de dados');
mysql_select_db($base_dados, $ligacao);
?>