import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import Button from '../src/components/Button';

test('renders button and responds to click', async () => {
  const user = userEvent.setup();
  const handleClick = jest.fn();
  render(<Button label="Click Me" onClick={handleClick} />);

  const button = screen.getByText('Click Me');
  await user.click(button);

  expect(handleClick).toHaveBeenCalledTimes(1);
});
