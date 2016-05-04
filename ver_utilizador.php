<?php
//ligar à base de dados
$ligacao = mysql_connect('localhost', 'root', '') or die ('Nao foi possivel ligqar a base de dados');
//activar a base de dados pretendida
mysql_select_db('gestao_utilizadores', $ligacao) or die (mysql_error($ligacao));
//criar a consulta a base de dados
$sql = 'SELECT * FROM Clientes ORDER BY nome_cliente ASC';
//criar a variavel $consulta que guarda os resultados obtidos, ordenados por nome de forma ascendente
$consulta = mysql_query($sql);
//verificar se existem resultados e mostra-los
if($consulta) {
//construir tabela para apresentar os dados
include('menu.php');
echo(<table width="600px" align="left" border=0>);
echo(<tr><font face="Arial" align="center">Lista de utilizadores</tr><br/>);
echo(<tr><td width="100px" align="center" bgcolor="#99cc33"><font face="Arial" size="2">Nº registo</td>
<td width="200px" align="center" bgcolor="#99cc33"><font face="Arial" size="2">Nome de utilizador</td>
<td width="300px" align="center" bgcolor="#99cc33"><font face="Arial" size="2">Endereço de correio electronico</td></tr>);
//percorrer o array
while($mostrar = mysql_fetch_array($consulta)){
$id_utilizador = $mostrar["id_utilizador"];
$nome_utilizador = $mostrar["nome_utilizador"];
$email = $mostrar["email"];
//caso haja registos, mostra-nos na tabela
echo(<tr><td align=\"center\">$id_utilizador</td><td align=\"center\">$email</td></tr>); }
echo("</table>"); }
//caso haja registos, informa o utilizador
else { echo ("A base de dados nao contem registos");
}
//libertar variavel da memoria
mysql_free_result($consulta);
?>