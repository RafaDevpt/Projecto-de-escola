<?php
//verificar se houve preenchimento dos campos das variaveis
if (!empty($_POST) AND (empty($_POST['nome']) OR empty($_POST['password']))) {
header("Location: index.php");
exit;
}
//ligar à base de dados
$ligacao = mysql_connect('localhost', 'root2', '') or die ('Nao foi possivel ligar a base de dados');
//seleccionar base de dados pretendida
mysql_select_db ('Epalte_ONLINE', $ligacao) or die (mysql_error($ligacao));
//definir variaveis $username and $password 
$username=$_POST['nome'];
$password=$_POST['password'];
//consultar base de dados
$sql="SELECT nome_utilizador, palavra_passe FROM utilizadores WHERE nome_utilizador='$username' AND palavra_passe='$password'";
$consulta = mysql_query($sql);
//verificar se foram devolvidos dados
if(mysql_num_rows($consulta)==1){
//remeter o utilizador conforme os dados obtidos
//se existem dados, remete para o menu
header("Location: menu_admin.php");
exit;
//se nao existem dados, remete para login
}
else {
header("Location: index.php");
exit;
}
mysql_free_result();
?>