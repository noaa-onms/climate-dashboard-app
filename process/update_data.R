# load packages ----
librarian::shelf(
  dplyr, fs, gitcreds, glue, here, logger, quarto, stringr, yaml)

# setup cron
# sudo apt update
# sudo apt install cron
# sudo systemctl enable cron
# crontab -e
# minute hour day_of_month month day_of_week command_to_run
# 0 0 * * * cd /share/github/noaa-onms/climate-dashboard-app; Rscript process/update_data.R > log/update_data_cron.txt 2>&1
# sudo service cron restart

# paths ----
dir_meta   <- here("meta")
dir_log    <- here("log")
dir_proc   <- here("process")
dir_data   <- here("data")
log_txt    <- glue("{dir_log}/update_data_log.txt")
do_git     <- T # DEBUG

# git ----
github_pat <- gitcreds_get(use_cache = FALSE)$password
stopifnot(str_sub(github_pat, 1, 3) == "ghp")
if (do_git)
  system("git pull")

# log ----
if (file_exists(log_txt))
  file_delete(log_txt)
log_appender(appender_tee(log_txt))
log_tictoc("Script starting up...")

# iterate over dataset ymls ----
ymls <- dir_ls(dir_meta, regexp = ".*\\.(ya?ml)$")
for (yml in ymls){  # yml = ymls[2]

  # * setup qmd ----
  tryCatch({

    # parameters
    params          <- read_yaml(yml)
    params$data_var <- path_ext_remove(basename(yml))

    # qmd
    proc_qmd <- glue("{dir_proc}/erddap.qmd")  # TODO: switch to copernicus based on params
    log_qmd  <- glue("{dir_log}/{params$data_var}.qmd")
    file_copy(proc_qmd, log_qmd, overwrite = T)

  }, error = function(e) {
    log_error("Error reading {basename(yml)}: {conditionMessage(e)}")
  })

  # * render qmd ----
  log_tictoc("meta/{basename(yml)} -[ process/{basename(proc_qmd)} ]-> data/{params$data_var}/*, log/{params$data_var}.html")
  tryCatch({

    quarto_render(
      input          = log_qmd,
      execute_params = params)

    file_delete(log_qmd)

  }, error = function(e) {
    log_error("Error rendering {basename(yml)} -[ log/{basename(log_qmd)} ]-> log/{params$data_var}.html}: {conditionMessage(e)}")
  })

}

# git push ----
log_tictoc("Script done rendering, next git commit & push")

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
