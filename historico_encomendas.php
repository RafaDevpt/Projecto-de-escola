<?php
//inicar sessao
session_start();
//ligacao a base de dados
include("ligacao_db.php");
//verificar se o utilizador ja realizou o acesso
/*if (!isset($_SESSION['nivel_utilizador'])) {
echo "<tr>Nao esta autorizado a aceder a esta pagina!</tr>";
echo "<tr><a href='index.php'>Clique para voltar a pagina incial!</a></tr>";}*/
//Pesquisar a base de dados
$sql_encomendas = "SELECT * FROM compra_confirmada WHERE estado_compra='0'";
$consulta = mysql_query($sql_encomendas);
$resultado = mysql_num_rows($consulta);
//caso nao existam resultados, avisar o utilizador
if ($resultado == 0) {
echo "<tr> Nao existem compras!</tr>";
echo "<tr><a href='menu_admin.php'>Clique para voltar ao menu inicial!</a></tr>";}
//caso contrario, exibir os resultados encontrados 
else {
echo "<table width='800' border='1' align='center'>";
echo "<tr><td colspan='4' align='center'>Historico de encomendas</td></tr>";
echo "<th>Nº encomenda</th><th> Nº cliente</th><th>data da compra</th><th>Estado da compra</th>";
//percorrer todos os registos para serem exibidos
while ($mostrar = mysql_fetch_array($consulta)) {
extract($mostrar);
echo '<tr><td>$id_compra</td>
<td align=\"center\" width=\"50\">$id_cliente</td>
<td align=\"center\">$data_compra</td>
<td align=\"center\">';
//assinalar de forma colorida cada estado
if($estado_compra == '0') {
echo"<font color='#FFFF00'>Pendente";
}
elseif($estado_compra == '1') {
echo "<font color='#009900'>Expedida";
}
elseif($estado_compra == '2') {
echo "<font color='#FF0000'>Terminada";
}
echo "</td></tr>";
}
//apresentar hiperligacao para voltar ao menu
echo'<p align="center">Clique<a href="menu_admin.php">aqui</a>para voltar ao menu de administraçao</p>';
echo "</table>";
}
}
?>