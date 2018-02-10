describe Pheromone do
  context '#enabled?' do
    context 'returns false when pheromone config is disabled' do
      before do
        Pheromone::Config.configure do |config|
          config.enabled = false
        end
      end

      it 'returns false' do
        expect(Pheromone.enabled?).to be false
      end
    end

    context 'returns true when pheromone config is enabled' do
      before do
        Pheromone::Config.configure do |config|
          config.enabled = true
        end
      end

      it 'returns false' do
        expect(Pheromone.enabled?).to be true
      end
    end
  end
end
