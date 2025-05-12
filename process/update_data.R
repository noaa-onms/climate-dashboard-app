librarian::shelf(
  dplyr, fs, gitcreds, glue, here, logger, quarto, stringr, yaml)

# setup cron ----
# sudo apt update
# sudo apt install cron
# sudo systemctl enable cron
# crontab -e
# minute hour day_of_month month day_of_week command_to_run
# 0 0 * * * cd /share/github/noaa-onms/climate-dashboard-app; Rscript process/update_data.R > log/update_data_cron.txt 2>&1
# sudo service cron restart

dir_meta   <- here("meta")
dir_log    <- here("log")
log_txt    <- glue("{dir_log}/update_data_log.txt")
do_git     <- TRUE

github_pat <- gitcreds_get(use_cache = FALSE)$password
stopifnot(str_sub(github_pat, 1, 3) == "ghp")
if (do_git)
  system("git pull")

if (file_exists(log_txt))
  file_delete(log_txt)
log_appender(appender_tee(log_txt))
log_info("Script starting up...")

for (yaml in dir_ls(dir_meta, glob = "*.yaml")){ # yaml = dir_ls(dir_meta, glob = "*.yaml")[1]

  tryCatch({

    # parameters
    params          <- read_yaml(yaml)
    params$data_var <- path_ext_remove(basename(yaml))

    # paths
    in_qmd   <- here("process/erddap.qmd")  # TODO: switch to copernicus based on params
    tmp_html <- glue("{params$data_var}.html")
    out_html <- here(glue("{dir_log}/{params$data_var}.html"))

  }, error = function(e) {
    log_error("Error reading {basename(yaml)}: {conditionMessage(e)}")
  })

  log_info("meta/{basename(yaml)} -[ {basename(in_qmd)} ]-> data/{params$data_var}/*, log/{basename(out_html)}")

  tryCatch({

    quarto_render(
      input          = in_qmd,
      output_format  = "html",
      output_file    = tmp_html,
      execute_params = params,
      execute_dir    = dirname(in_qmd),
      pandoc_args    = "--embed-resources")

    file_move(glue("{dirname(in_qmd)}/{tmp_html}"), out_html)

  }, error = function(e) {
    log_error("Error rendering {basename(yaml)} -[ {basename(in_qmd)} ]-> {basename(out_html)}: {conditionMessage(e)}")
  })

}
log_info("Script done rendering, next git commit & push")

# setup in Terminal
# git config --global user.name "$github_username"
# git config --global user.email "$github_email"
# git add --all; git commit -m 'test creds'; git push
# # enter GITHUB_PAT on password prompt
# git config --global credential.helper store

if (do_git){
  system("git add --all")
  system("git commit -m 'ran update_data.R'")
  system("git push")
}
