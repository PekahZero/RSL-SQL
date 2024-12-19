cd /home/jyw/Projects/RSL-SQL/
conda actiavte rslsql

export http_proxy="socks5://10.176.24.76:10802";export https_proxy="socks5://10.176.24.76:10802"

start_index = 0
# 1. data preprocessing

# Construct `ppl_dev.json`. 
python src/data_construct.py 
#Construct few-shot examples pairs
python few_shot/construct_QA.py 
# Generate few-shot examples
python few_shot/slg_main.py --dataset src/information/ppl_dev.json \
                --out_file src/information/example.json --kshot 3
# add few-shot examples to ppl_dev.json
python src/information/add_example.py


# 2. preliminary sql generation and bidirectional schema linking

# step 1: preliminary sql
# There are two output files in this step,
# one is `src/sql_log/preliminary_sql.txt` and the other is `src/schema_linking/LLM.json`
# If an error occurs, you need to save these two files in time, then continue running and save the subsequent results.
python src/step_1_preliminary_sql.py --ppl_file src/information/ppl_dev.json \
                            --sql_out_file src/sql_log/preliminary_sql.txt \
                            --Schema_linking_LLM src/schema_linking/LLM.json \
                            --start_index ${start_index}
# schema linking
python src/bid_schema_linking.py --pre_sql_file src/sql_log/preliminary_sql.txt \
                            --sql_sl_output src/schema_linking/sql.json \
                            --hint_sl_output src/schema_linking/hint.json \
                            --LLM_sl_output src/schema_linking/LLM.json \
                            --Schema_linking_output src/schema_linking/schema.json
cp src/schema_linking/schema.json src/information
# add schema linking to ppl_dev.json
python src/information/add_sl.py

# 3. SQL Generation based simplified schema and Information augmentation

# step 2: sql generation
# There are two output files in this step,
# one is `src/sql_log/step_2_information_augmentation.txt` and the other is `src/information/augmentation.json`
# If an error occurs, you need to save these two files in time, then continue running and save the subsequent results.
python src/step_2_information_augmentation.py --ppl_file src/information/ppl_dev.json \
                                        --sql_2_output src/sql_log/step_2_information_augmentation.txt \
                                        --information_output src/information/augmentation.json \
                                        --start_index ${start_index}
# add augmentation to ppl_dev.json
python src/information/add_augmentation.py

# 4. SQL selection

# step 3: sql selection
# There is one output files in this step, one is `src/sql_log/step_3_binary.txt`.
# If an error occurs, you need to save these two files in time, then continue running and save the subsequent results.
python src/step_3_binary_selection.py --ppl_file src/information/ppl_dev.json \
                        --sql_3_output src/sql_log/step_3_binary.txt \
                        --sql_1 src/sql_log/preliminary_sql.txt \
                        --sql_2 src/sql_log/step_2_information_augmentation.txt \
                        --start_index ${start_index}

# 5. SQL refinement
# step 4: sql refinement
# There is one output files in this step, one is `src/sql_log/final_sql.txt`.
python src/step_4_self_correction.py --ppl_file src/information/ppl_dev.json \
                                    --sql_4_output src/sql_log/final_sql.txt \
                                    --sql_refinement src/sql_log/step_3_binary.txt \
                                    --start_index ${start_index}
