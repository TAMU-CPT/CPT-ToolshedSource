.PHONY: run_planemo

run_planemo_init_for_all:
	for dir in cpt_*/ ; do \
   		dirname=$${dir%/*}; \
   		cd $$dirname; \
   		planemo shed_init ./ --name="$$dirname" --owner=cpt; \
		cd ..; \
	done

update_all_toolshed_repos:
	for dir in cpt_*/ ; do \
		dirname=$${dir%/*}; \
		cd $$dirname; \
		planemo shed_update --shed_target="toolshed"; \
		cd ..; \
	done

