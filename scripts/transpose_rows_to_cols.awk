# transposes rows in a comma delimited file, to columns in a tab delimited file
# usage: write on Terminal $ awk -f transpose_rows_to_cols.awk input.rows.txt > output.cols.txt

BEGIN {FS=","}

{
for (i=1;i<=NF;i++)
{
 arr[NR,i]=$i;
 if(big <= NF)
  big=NF;
 }
}
 
END {
  for(i=1;i<=big;i++)
   {
    for(j=1;j<=NR;j++)
    {
     printf("%s\t",arr[j,i]);
    }
    printf("\n");
   }
}
