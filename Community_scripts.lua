                                script_bot.filterScripts(script_bot.widget.searchBar:getText());

                            end
                        end

                        -- Main execution flow
                        do
                            script_bot.readScripts();
                            script_bot.onLoading();
                        end

                        -- Check for version update
                        if script_manager.actualVersion ~= actualVersion then
                            script_bot.buttonRemoveJson:show();
                            updateLabel:show();
                        end
                    end
                end
            end
        end
    end);
end
