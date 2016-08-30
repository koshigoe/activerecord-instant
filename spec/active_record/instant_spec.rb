require 'spec_helper'

describe ActiveRecord::Instant do
  it 'has a version number' do
    expect(ActiveRecord::Instant::VERSION).not_to be nil
  end

  let(:instant) { ActiveRecord::Instant.new('instant_models', extensions: extensions) }
  let(:extensions) { [] }

  describe '#table_name' do
    subject { instant.table_name(options) }

    context 'temporary: none' do
      let(:options) { {} }
      it { is_expected.to eq 'instant_models' }
    end

    context 'temporary: false' do
      let(:options) { { temporary: false } }
      it { is_expected.to eq 'instant_models' }
    end

    context 'temporary: true' do
      let(:options) { { temporary: true } }
      it { is_expected.to eq 'temporary_instant_models' }
    end
  end

  describe '#table_exists?' do
    subject { instant.table_exists? }

    context 'table exists' do
      before { ActiveRecord::Base.connection.create_table(:instant_models, force: true) }

      it { is_expected.to be_truthy }
    end

    context 'table does not exist' do
      it { is_expected.to be_falsey }
    end
  end

  describe '#stale_table_name' do
    subject { instant.stale_table_name }

    it { is_expected.to eq 'stale_instant_models' }
  end

  describe '#create_table!' do
    subject do
      instant.create_table!(options) do |t|
        t.string :column_1, null: true
        t.string :column_2, null: true
        t.timestamps null: true
      end
    end

    context 'temporary: false' do
      let(:options) { { temporary: false } }

      it 'create a table' do
        expect { subject }
          .to change { ActiveRecord::Base.connection.data_source_exists?('instant_models') }.to(true)
      end

      it 'has specified columns' do
        subject
        column_names = ActiveRecord::Base.connection.columns('instant_models').map(&:name)
        expect(column_names).to contain_exactly('id', 'column_1', 'column_2', 'created_at', 'updated_at')
      end
    end

    context 'temporary: true' do
      let(:options) { { temporary: true } }

      it 'テーブルを作る' do
        expect { subject }
          .to change { ActiveRecord::Base.connection.data_source_exists?('temporary_instant_models') }.to(true)
      end

      it '指定したカラムを作る' do
        subject
        column_names = ActiveRecord::Base.connection.columns('temporary_instant_models').map(&:name)
        expect(column_names).to contain_exactly('id', 'column_1', 'column_2', 'created_at', 'updated_at')
      end
    end
  end

  describe '#model' do
    subject { instant.model(options) }

    let(:options) { {} }

    it 'return subclass of ActiveRecord::Base' do
      expect(subject).to be < ActiveRecord::Base
    end

    context 'has not been defined yet' do
      context 'temporary: false' do
        let(:options) { { temporary: false } }

        before do
          Object.send(:remove_const, :InstantModel) if Object.const_defined?(:InstantModel)
        end

        it 'define class' do
          expect { subject }.to change { Object.const_defined?(:InstantModel) }
        end

        it 'increase a subclass of ActiveRecord::Base' do
          expect { subject }.to change { ActiveRecord::Base.subclasses.size }.by(1)
        end
      end

      context 'temporary: true' do
        let(:options) { { temporary: true } }

        before do
          Object.send(:remove_const, :TemporaryInstantModel) if Object.const_defined?(:TemporaryInstantModel)
        end

        it 'define class' do
          expect { subject }.to change { Object.const_defined?(:TemporaryInstantModel) }
        end

        it 'increase a subclass of ActiveRecord::Base' do
          expect { subject }.to change { ActiveRecord::Base.subclasses.size }.by(1)
        end
      end
    end

    context 'has already been defined' do
      around do |example|
        Object.send(:remove_const, :InstantModel) if Object.const_defined?(:InstantModel)
        klass = Class.new(ActiveRecord::Base)
        Object.const_set('InstantModel', klass)

        example.run

        Object.send(:remove_const, :InstantModel) if Object.const_defined?(:InstantModel)
      end

      it 'does not increase subclass of ActiveRecord::Base' do
        expect { subject }.not_to change { ActiveRecord::Base.subclasses.size }
      end
    end
  end

  describe '#promote_temporary_table!' do
    subject { instant.promote_temporary_table! }

    context 'temporary table exists' do
      before do
        instant.create_table!(temporary: true) do |t|
          t.string :column_1, null: true
          t.string :column_2, null: true
          t.timestamps null: true
        end
      end

      it 'temporary table is gone' do
        expect { subject }
          .to change { ActiveRecord::Base.connection.data_source_exists?('temporary_instant_models') }.to(false)
      end

      context 'main table does not exist' do
        it 'create main table' do
          expect { subject }
            .to change { ActiveRecord::Base.connection.data_source_exists?('instant_models') }.to(true)
        end
      end

      context 'main table exists' do
        before do
          instant.create_table! do |t|
            t.string :column_1, null: true
            t.timestamps null: true
          end
        end

        it 'main table has been existed' do
          expect { subject }
            .not_to change { ActiveRecord::Base.connection.data_source_exists?('instant_models') }
        end

        it 'change definition of main table' do
          expect { subject }
            .to change { ActiveRecord::Base.connection.columns('instant_models').map(&:name) }
            .to(contain_exactly('id', 'column_1', 'column_2', 'created_at', 'updated_at'))
        end
      end

      context 'stale table exists' do
        before do
          ActiveRecord::Base.connection.create_table(:stale_instant_models, force: true)
        end

        it 'drop stale table' do
          expect { subject }
            .to change { ActiveRecord::Base.connection.data_source_exists?('stale_instant_models') }.to(false)
        end
      end
    end

    context 'temporary table does not exist' do
      it 'raise ActiveRecord::Instant::TemporaryTableNotExist' do
        expect { subject }.to raise_error(ActiveRecord::Instant::TemporaryTableNotExist)
      end
    end
  end

  describe '#drop_tables!' do
    subject { instant.drop_tables! }

    context 'tables exist' do
      before do
        ActiveRecord::Base.connection.create_table(:temporary_instant_models, force: true)
        ActiveRecord::Base.connection.create_table(:instant_models, force: true)
        ActiveRecord::Base.connection.create_table(:stale_instant_models, force: true)
      end

      it 'drop temporary table' do
        expect { subject }
          .to change { ActiveRecord::Base.connection.data_source_exists?('temporary_instant_models') }.to(false)
      end

      it 'drop main table' do
        expect { subject }
          .to change { ActiveRecord::Base.connection.data_source_exists?('instant_models') }.to(false)
      end

      it 'drop stale table' do
        expect { subject }
          .to change { ActiveRecord::Base.connection.data_source_exists?('stale_instant_models') }.to(false)
      end
    end

    context 'tables not exist' do
      before do
        ActiveRecord::Base.connection.execute 'DROP TABLE IF EXISTS temporary_instant_models;'
        ActiveRecord::Base.connection.execute 'DROP TABLE IF EXISTS instant_models;'
        ActiveRecord::Base.connection.execute 'DROP TABLE IF EXISTS stale_instant_models;'
      end

      it 'can run' do
        expect { subject }.not_to raise_error
      end
    end
  end
end
