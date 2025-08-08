#!/bin/bash

# log name
LOG="pangenome_analysis.log"
echo "Starting pangenome analysis..." | tee $LOG

# 1. Run get_homologues with all clusters (not just the core)
echo -e "\n[1] Running get_homologues..." | tee -a $LOG
get_homologues.pl -d Bacillus/ -P -t 0 -M -A -n 6 2>&1 | tee -a $LOG

# -t 0 → includes all occupancy levels (not just core)
# -P   → calculates the percentage of conserved proteins
# -M   → uses the OrthoMCL algorithm
# -A   → generates all auxiliary files
# -n 6 → uses 6 threads

# 2. Run compare_clusters to obtain the pangenome matrix
echo -e "\n[2] Running compare_clusters..." | tee -a $LOG
compare_clusters.pl -d Bacillus_homologues/BacillusvelezensisMEP218_f0_0taxa_algOMCL_e0_ -m -o matrices 2>&1 | tee -a $LOG

# 3. Confirm which columns correspond to the curated and original assemblies
echo -e "\n[3] Identifying curated and original columns:" | tee -a $LOG
echo -n "Column 4: " | tee -a $LOG
perl -lane 'print $F[4]' matrices/pangenome_matrix_t0.tr.tab | head -1 | tee -a $LOG

echo -n "Column 5: " | tee -a $LOG
perl -lane 'print $F[5]' matrices/pangenome_matrix_t0.tr.tab | head -1 | tee -a $LOG

# 4. Calculate occupancy sum per cluster
echo -e "\n[4] Occupancy sum for clusters where curated or original appear:" | tee -a $LOG
perl -lane '
  $oc=0;
  foreach $g (1 .. $#F) { $oc++ if($F[$g]>0) }
  if($F[4]>0){ $tcur+=$oc }
  if($F[5]>0){ $tori+=$oc }
  END { print "cur=$tcur ori=$tori" }
' matrices/pangenome_matrix_t0.tr.tab | tee -a $LOG

# 5. Count singletons (unique clusters per assembly)
echo -e "\n[5] Counting unique clusters (singletons):" | tee -a $LOG

echo -n "Singletons in curated: " | tee -a $LOG
perl -lane 'if(/0\t0\t0\t\d+\t0\t0\t0\t0\t0\t0\t0/){ print }' matrices/pangenome_matrix_t0.tr.tab | wc | tee -a $LOG

echo -n "Singletons in original: " | tee -a $LOG
perl -lane 'if(/0\t0\t0\t0\t\d+\t0\t0\t0\t0\t0\t0/){ print }' matrices/pangenome_matrix_t0.tr.tab | wc | tee -a $LOG

# 6. Extract singleton clusters from curated
echo -e "\n[5] Unique clusters (singletons) where only curated appears:" | tee -a $LOG
perl -lane 'if(/0\t0\t0\t\d+\t0\t0\t0\t0\t0\t0\t0/){ print }' matrices/pangenome_matrix_t0.tr.tab | tee -a $LOG

# 7. Extract singleton clusters from original
echo -e "\n[6] Unique clusters (singletons) where only original appears:" | tee -a $LOG
perl -lane 'if(/0\t0\t0\t0\t\d+\t0\t0\t0\t0\t0\t0/){ print }' matrices/pangenome_matrix_t0.tr.tab | tee -a $LOG

echo -e "\nAnalysis completed." | tee -a $LOG