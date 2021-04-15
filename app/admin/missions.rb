# frozen_string_literal: true

# rubocop: disable Metrics/BlockLength
ActiveAdmin.register Mission do
  permit_params :author_id,
                :name,
                :description,
                :genre,
                :delivery_expected,
                :max_member_count,
                :min_member_count,
                :start_date,
                :due_date,
                :cash_register_proficiency_requirement,
                :recurrent_change

  menu if: proc { authorized? :index, %i[active_admin Mission] } # display menu according to ActiveAdmin::Policy

  index do
    selectable_column
    column :name
    column :description
    column :delivery_expected
    column(:genre) { |mission| Mission.human_enum_name(:genre, mission.genre) }
    column :due_date
    column :author
    column :cash_register_proficiency_requirement do |mission|
      Mission.human_enum_name('cash_register_proficiency_requirement', mission.cash_register_proficiency_requirement)
    end
    actions
  end

  form do |f|
    f.inputs do
      f.input :author,
              as: :select,
              collection: Member.pluck(:email, :id),
              selected: Member.pluck(:email, :id).find { |_mail, id| id == f.object.author_id }
      f.input :name
      f.input :description
      f.input :delivery_expected
      f.input :genre
      f.input :max_member_count
      f.input :min_member_count
      f.input :start_date
      f.input :due_date
      f.input :cash_register_proficiency_requirement,
              :as => :select,
              collection => Mission.cash_register_proficiency_requirements
      f.input :recurrent_change, as: :boolean if f.object.persisted?
    end

    actions
  end

  show do
    attributes_table do
      row :name
      row :description
      row :start_date
      row :due_date
      row :min_member_count
      row :max_member_count
      row :delivery_expected
      row(:genre) { |mission| Mission.human_enum_name(:genre, mission.genre) }
      row(:cash_register_proficiency_requirement) do |resource|
        Mission.human_enum_name('cash_register_proficiency_requirement', resource.cash_register_proficiency_requirement)
      end
    end

    panel 'Participants' do
      table_for resource.enrollments do
        column :member
        column(:start_time) { |enrollment| enrollment.start_time.strftime('%H:%M') }
        column(:end_time) { |enrollment| enrollment.end_time.strftime('%H:%M') }
        column 'actions' do |enrollment|
          link_to(t('active_admin.edit'), edit_admin_mission_enrollment_path(mission, enrollment)) +
            ' ' +
            link_to(t('active_admin.delete'), admin_mission_enrollment_path(mission, enrollment), method: :delete)
        end
      end
    end
  end

  controller do
    def create # rubocop:disable Metrics/AbcSize
      build_resource
      if resource.save
        flash[:notice] = translate '.record_created'
        redirect_to admin_mission_path(resource.id)
      else
        flash[:error] = resource.errors.full_messages.join
        render :new
      end
    end

    def update
      transaction_result = update_transaction
      if transaction_result.success?
        flash[:notice] = translate '.confirm_update'
        redirect_to admin_mission_path(resource.id)
      else
        flash[:error] = transaction_result.failure
        render :edit
      end
    end

    private

    def update_transaction
      input = { params: permitted_params[:mission], mission: resource }
      if permitted_params[:mission][:recurrent_change]
        Admin::Missions::RecurrentUpdateTransaction.new.call(input)
      else
        Admin::Missions::UpdateTransaction.new.call(input)
      end
    end
  end

  action_item :create_enrollment, only: :show do
    link_to t('active_admin.new_model', model: Enrollment.model_name.human),
            new_admin_mission_enrollment_path(resource)
  end

  action_item :generate_schedule, only: :index do
    dropdown_menu t('.generate_schedule') do
      (1..6).each do |n|
        item n,
             generate_schedule_admin_missions_path(months_count: n),
             method: :post,
             data: { confirm: t('.confirm_generation_schedule') }
      end
    end
  end

  collection_action :generate_schedule, method: :post do
    generated = false
    (1..params[:months_count].to_i).each do |n|
      current_month = (DateTime.current + n.month).at_beginning_of_month
      if HistoryOfGeneratedSchedule.find_by(month_number: current_month).nil?
        GenerateScheduleJob.perform_later(current_member: current_member, current_month: current_month.to_s)
        generated = true
      end
    end

    feedback_message = generated ? t('.schedule_generation_in_progress') : t('.schedule_already_generated')

    redirect_to admin_missions_path, notice: feedback_message
  end
end
# rubocop: enable Metrics/BlockLength
