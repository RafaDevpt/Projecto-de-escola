<?php
include('verificar_admin.php');
//registar categoria
if(isset($_REQUEST['registar'])) {
//ligacao a base de dados
include('ligacao_db.php');
/* PT-PT: $_POST entrava directamente no INSERT: uma aspa no nome da
          categoria bastava para terminar a string e acrescentar SQL. A
          extensao mysql_* nao tem consultas preparadas, por isso escapa-se.
          A verificacao de duplicado tambem so lia a PRIMEIRA linha da
          tabela, pelo que nao detectava nada -- passa a perguntar pelo nome.
   EN-UK: $_POST went straight into the INSERT: a single quote in the
          category name was enough to close the string and append SQL. The
          mysql_* extension has no prepared statements, so we escape. The
          duplicate check also only read the FIRST row of the table and so
          detected nothing -- it now asks for the name. */
$nome_cat = mysql_real_escape_string($_POST['nome_cat'], $ligacao);
$sql_categoria = "SELECT nome_categoria FROM categorias WHERE nome_categoria='$nome_cat'";
$consulta1 = mysql_query($sql_categoria, $ligacao);
if ($consulta1 && mysql_num_rows($consulta1) > 0) {
//caso a categoria ja existe, informa o utilizador
echo "Ja existe uma categoria com o nome que inseriu!";
}
else {
//registar nova categoria
$sql_nova_cat = "INSERT INTO categorias(nome_categoria) VALUES('$nome_cat')";
//$sql_nova_cat= "INSERT INTO categorias(nome_categoria) VALUES('fr4utas')";
$consulta2 = mysql_query($sql_nova_cat, $ligacao);
//remeter para menu
header("Location: menu_admin.php");
}}
?>
<table width="800" border="1" align="center">
<form id="form_registo" name="form_registo" method="POST" action="adicionar_categoria.php">
<td>Nome da categoria: <input type="text" name="nome_cat" size="20" id="nome_cat"/>(obrigatorio)</td>
<p>
<td><input type="submit" name="registar" id="registar" value="Registar"/>
<input type="reset" name="apagar" id="apagar" value="Apagar"/></td>
</p>
</form>
<td colspan="4" align="center"><p>Clique<a href="menu_admin.php"> aqui </a> para voltar ao menu de administraçao</p></td>
</table>