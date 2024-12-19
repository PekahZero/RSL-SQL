source activate rslsql

type='science'

export http_proxy="socks5://10.176.24.76:10802";export https_proxy="socks5://10.176.24.76:10802"

start_index=0
# 1. data preprocessing

# src/information/{type}/ppl_dev.json
python src/data_construct.py 
# few_shot/{type}/QA.json
python few_shot/construct_QA.py 
# src/information/{type}/example.json
python few_shot/slg_main.py --dataset src/information/${type}/ppl_dev.json \
                --out_file src/information/${type}/example.json --kshot 3

# python few_shot/slg_main.py --dataset src/information/science/ppl_dev.json \
#                 --out_file src/information/spider/example.json --kshot 3
python src/information/add_example.py


# 2. preliminary sql generation and bidirectional schema linking

# step 1: preliminary sql
python src/step_1_preliminary_sql.py --ppl_file src/information/${type}/ppl_dev.json \
                            --sql_out_file src/sql_log/${type}/preliminary_sql.txt \
                            --Schema_linking_LLM src/schema_linking/${type}/LLM.json \
                            --start_index ${start_index}

# python src/step_1_preliminary_sql.py --ppl_file src/information/spider/ppl_dev.json \
#                             --sql_out_file src/sql_log/spider/preliminary_sql.txt \
#                             --Schema_linking_LLM src/schema_linking/spider/LLM.json \
#                             --start_index 0

# schema linking
python src/bid_schema_linking.py --pre_sql_file src/sql_log/${type}/preliminary_sql.txt \
                            --sql_sl_output src/schema_linking/${type}/sql.json \
                            --hint_sl_output src/schema_linking/${type}/hint.json \
                            --LLM_sl_output src/schema_linking/${type}/LLM.json \
                            --Schema_linking_output src/schema_linking/${type}/schema.json

# python src/bid_schema_linking.py --pre_sql_file src/sql_log/spider/preliminary_sql.txt \
#                             --sql_sl_output src/schema_linking/spider/sql.json \
#                             --hint_sl_output src/schema_linking/spider/hint.json \
#                             --LLM_sl_output src/schema_linking/spider/LLM.json \
#                             --Schema_linking_output src/schema_linking/spider/schema.json

cp src/schema_linking/${type}/schema.json src/information/${type}
# cp src/schema_linking/spider/schema.json src/information/spider
python src/information/add_sl.py

# 3. SQL Generation based simplified schema and Information augmentation
python src/step_2_information_augmentation.py --ppl_file src/information/${type}/ppl_dev.json \
                                        --sql_2_output src/sql_log/${type}/step_2_information_augmentation.txt \
                                        --information_output src/information/${type}/augmentation.json \
                                        --start_index ${start_index}

# python src/step_2_information_augmentation.py --ppl_file src/information/spider/ppl_dev.json \
#                                         --sql_2_output src/sql_log/spider/step_2_information_augmentation.txt \
#                                         --information_output src/information/spider/augmentation.json \
#                                         --start_index 0

python src/information/add_augmentation.py

# 4. SQL selection
python src/step_3_binary_selection.py --ppl_file src/information/${type}/ppl_dev.json \
                        --sql_3_output src/sql_log/${type}/step_3_binary.txt \
                        --sql_1 src/sql_log/${type}/preliminary_sql.txt \
                        --sql_2 src/sql_log/${type}/step_2_information_augmentation.txt \
                        --start_index ${start_index}


# python src/step_3_binary_selection.py --ppl_file src/information/spider/ppl_dev.json \
#                         --sql_3_output src/sql_log/spider/step_3_binary.txt \
#                         --sql_1 src/sql_log/spider/preliminary_sql.txt \
#                         --sql_2 src/sql_log/spider/step_2_information_augmentation.txt \
#                         --start_index 0
# 5. SQL refinement
python src/step_4_self_correction.py --ppl_file src/information/${type}/ppl_dev.json \
                                    --sql_4_output src/sql_log/${type}/final_sql.txt \
                                    --sql_refinement src/sql_log/${type}/step_3_binary.txt \
                                    --start_index ${start_index}

# python src/step_4_self_correction.py --ppl_file src/information/spider/ppl_dev.json \
#                                     --sql_4_output src/sql_log/spider/final_sql.txt \
#                                     --sql_refinement src/sql_log/spider/step_3_binary.txt \
#                                     --start_index 0