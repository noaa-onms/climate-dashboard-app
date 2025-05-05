librarian::shelf(
  dplyr, fs, glue, here, logger, quarto, yaml)

dir_meta <- here("meta")
dir_log  <- here("log")
log_txt  <- glue("{dir_log}/update_data.txt")

if (file_exists(log_txt))
  file_delete(log_txt)
log_appender(appender_tee(log_txt))
log_info("Script starting up...")

for (yaml in dir_ls(dir_meta, glob = "*.yaml")){ # yaml = dir_ls(dir_meta, glob = "*.yaml")[1]

  tryCatch({

    # parameters
    y          <- read_yaml(yaml)
    y$data_var <- path_ext_remove(basename(yaml))

    # paths
    in_qmd   <- here("extractr.qmd")
    tmp_html <- path_ext_set(in_qmd, ".html")
    out_html <- here(glue("{dir_log}/{y$data_var}.html"))

  }, error = function(e) {
    log_error("Error reading {basename(yaml)}: {conditionMessage(e)}")
  })

  log_info("{basename(yaml)} -[ {basename(in_qmd)} ]-> {basename(out_html)}")

  tryCatch({

    quarto_render(
      input          = in_qmd,
      execute_params = y)

    file_move(tmp_html, out_html)

  }, error = function(e) {
    log_error("Error rendering {basename(yaml)} -[ {basename(in_qmd)} ]-> {basename(out_html)}: {conditionMessage(e)}")
  })

}
log_info("Script finished")

system(
  "git add --all;
   git commit -m 'ran update_data.R';
   git push")
