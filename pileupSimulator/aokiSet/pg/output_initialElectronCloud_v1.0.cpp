{
    
    /*
     
     2023.08.30 v1.0 by Yuma Aoki
     
     */
    
    // variables
    Int_t entry;
    Int_t num_hits;

    // read file
    TFile fin("XRPIX_RAWDATA_TMP1.tmp");
    // get tree
    TTree *input_tree = (TTree*)fin.Get("eventtree");

    // set address
    input_tree -> SetBranchAddress("num_hits", &num_hits);
    
    // set fp
    FILE *fp = fopen("outfile.txt", "w");
    
    // read entry
    entry = input_tree -> GetEntries();
    
    // output
    for ( Int_t i=0; i<entry; i++ ) {
        
        // input select Entry
        input_tree -> GetEntry(i);
        
        Flort_t edep[num_hits];
        Flort_t real_pos_x[num_hits];

        // set address
        input_tree -> SetBranchAddress("edep", &edep[0]);
        input_tree -> SetBranchAddress("real_pos_x", &real_pos_x[0]);

        fprintf(fp, "%d %f", EVENT_No, INT_TIME);
        // output
        for ( Int_t j=0; j<64; j++ ) {
            fprintf(fp, " %d", ADC[j]);
        }
        fprintf(fp, "\n");
        
    }
    
}

